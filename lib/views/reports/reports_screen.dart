import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../app_theme.dart';
import '../../services/app_state.dart';
import '../../models/transaction_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _period = 'today';
  DateTime? _customFrom;
  DateTime? _customTo;

  DateTimeRange _getRange() {
    final now  = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_period) {
      case 'today':
        return DateTimeRange(start: today, end: now);
      case 'week':
        return DateTimeRange(start: today.subtract(const Duration(days: 7)), end: now);
      case 'month':
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
      case 'year':
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
      case 'custom':
        return DateTimeRange(
          start: _customFrom ?? today.subtract(const Duration(days: 30)),
          end: _customTo ?? now,
        );
      default:
        return DateTimeRange(start: today, end: now);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##');
    return Consumer<AppState>(
      builder: (context, state, _) {
        final range  = _getRange();
        final report = state.buildReport(from: range.start, to: range.end);
        final totalSales     = report['totalSales'] as double;
        final totalPurchases = report['totalPurchases'] as double;
        final netProfit      = report['netProfit'] as double;
        final transactions   = report['transactions'] as List<ScrapTransaction>;
        final perProduct     = report['perProduct'] as Map<String, Map<String, dynamic>>;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('التقارير',
                              style: GoogleFonts.cairo(
                                  fontSize: 26, fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                          Text('${transactions.length} عملية في الفترة المحددة',
                              style: GoogleFonts.cairo(
                                  fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Period selector
                Row(
                  children: [
                    ...[
                      ('today',  'اليوم'),
                      ('week',   'الأسبوع'),
                      ('month',  'الشهر'),
                      ('year',   'السنة'),
                      ('custom', 'مخصص'),
                    ].map((e) => Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _PeriodBtn(
                        label: e.$2,
                        active: _period == e.$1,
                        onTap: () async {
                          if (e.$1 == 'custom') {
                            final r = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              builder: (context, child) => Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: const ColorScheme.dark(
                                    primary: AppColors.primary,
                                    surface: AppColors.card,
                                  ),
                                ),
                                child: child!,
                              ),
                            );
                            if (r != null) setState(() {
                              _customFrom = r.start;
                              _customTo   = r.end;
                              _period = 'custom';
                            });
                          } else {
                            setState(() => _period = e.$1);
                          }
                        },
                      ),
                    )),
                  ],
                ),
                const SizedBox(height: 24),

                // Summary Cards
                Row(
                  children: [
                    Expanded(child: _SummaryCard(
                      title: 'إجمالي المبيعات',
                      value: '${fmt.format(totalSales)} ج',
                      count: '${report['sellCount']} عملية',
                      icon: Icons.trending_up_rounded,
                      color: AppColors.profit,
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _SummaryCard(
                      title: 'إجمالي المشتريات',
                      value: '${fmt.format(totalPurchases)} ج',
                      count: '${report['buyCount']} عملية',
                      icon: Icons.trending_down_rounded,
                      color: AppColors.info,
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _SummaryCard(
                      title: 'صافي الربح',
                      value: '${fmt.format(netProfit)} ج',
                      count: netProfit >= 0 ? 'ربح 💰' : 'خسارة ⚠',
                      icon: Icons.monetization_on_rounded,
                      color: netProfit >= 0 ? AppColors.gold : AppColors.loss,
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _SummaryCard(
                      title: 'عمليات الخزنة',
                      value: '${fmt.format(totalSales - totalPurchases)} ج',
                      count: 'صافي دخل الخزنة',
                      icon: Icons.account_balance_wallet_rounded,
                      color: AppColors.primary,
                    )),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Per-product breakdown
                    Expanded(
                      flex: 2,
                      child: _buildPerProductTable(perProduct, fmt),
                    ),
                    const SizedBox(width: 20),
                    // Transactions list
                    Expanded(
                      flex: 3,
                      child: _buildTransactionsList(transactions, fmt),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPerProductTable(Map<String, Map<String, dynamic>> data, NumberFormat fmt) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Text('تقارير الأصناف',
                style: GoogleFonts.cairo(
                    fontSize: 15, fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
          ),
          const Divider(height: 1),
          if (data.isEmpty)
            Padding(
              padding: const EdgeInsets.all(30),
              child: Center(child: Text('لا توجد بيانات',
                  style: GoogleFonts.cairo(color: AppColors.textHint))),
            )
          else
            ...data.entries.map((e) {
              final p = e.value;
              final profit = (p['profit'] as double);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e.key,
                        style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold, fontSize: 14,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _miniStat('مبيعات', '${fmt.format(p['sales'])} ج', AppColors.profit),
                        const SizedBox(width: 8),
                        _miniStat('مشتريات', '${fmt.format(p['purchases'])} ج', AppColors.info),
                        const SizedBox(width: 8),
                        _miniStat('ربح', '${fmt.format(profit)} ج',
                            profit >= 0 ? AppColors.gold : AppColors.loss),
                      ],
                    ),
                    const Divider(height: 20),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(label, style: GoogleFonts.cairo(fontSize: 11, color: AppColors.textSecondary)),
              Text(value, style: GoogleFonts.cairo(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      );

  Widget _buildTransactionsList(List<ScrapTransaction> list, NumberFormat fmt) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Text('العمليات (${list.length})',
                style: GoogleFonts.cairo(
                    fontSize: 15, fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
          ),
          const Divider(height: 1),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.all(30),
              child: Center(child: Text('لا توجد عمليات في هذه الفترة',
                  style: GoogleFonts.cairo(color: AppColors.textHint))),
            )
          else
            ...list.take(15).map((t) {
              final color = t.isBuy ? AppColors.info : AppColors.profit;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        t.isBuy ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        size: 16, color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.productName, style: GoogleFonts.cairo(
                              fontSize: 13, fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary)),
                          Text('${t.typeAr} • ${fmt.format(t.weight)} كجم',
                              style: GoogleFonts.cairo(
                                  fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${fmt.format(t.totalPrice)} ج',
                            style: GoogleFonts.cairo(
                                fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                        if (t.isSell)
                          Text('ربح: ${fmt.format(t.netProfit)} ج',
                              style: GoogleFonts.cairo(fontSize: 11, color: AppColors.gold)),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _PeriodBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _PeriodBtn({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? Colors.black87 : AppColors.textSecondary)),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title, value, count;
  final IconData icon;
  final Color color;
  const _SummaryCard({
    required this.title, required this.value, required this.count,
    required this.icon, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textSecondary)),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: GoogleFonts.cairo(
              fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(count, style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
