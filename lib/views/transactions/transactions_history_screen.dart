import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../app_theme.dart';
import '../../services/app_state.dart';
import '../../models/transaction_model.dart';

class TransactionsHistoryScreen extends StatefulWidget {
  const TransactionsHistoryScreen({super.key});
  @override
  State<TransactionsHistoryScreen> createState() => _TransactionsHistoryScreenState();
}

class _TransactionsHistoryScreenState extends State<TransactionsHistoryScreen> {
  String _filter = 'all'; // all / buy / sell
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##');
    return Consumer<AppState>(
      builder: (context, state, _) {
        var list = state.getTransactions(
          type: _filter == 'buy' ? TransactionType.buy
              : _filter == 'sell' ? TransactionType.sell
              : null,
        );
        if (_search.isNotEmpty) {
          list = list.where((t) => t.productName.contains(_search)).toList();
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text('سجل العمليات',
                    style: GoogleFonts.cairo(
                        fontSize: 26, fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                Text('${state.transactions.length} عملية مسجلة',
                    style: GoogleFonts.cairo(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 20),

                // Filters row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (v) => setState(() => _search = v),
                        style: GoogleFonts.cairo(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'بحث بالصنف...',
                          prefixIcon: const Icon(Icons.search, color: AppColors.textHint, size: 20),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    _FilterChip('الكل',   'all',  Icons.list_rounded),
                    const SizedBox(width: 8),
                    _FilterChip('مشتريات', 'buy', Icons.arrow_downward_rounded),
                    const SizedBox(width: 8),
                    _FilterChip('مبيعات',  'sell', Icons.arrow_upward_rounded),
                  ],
                ),
                const SizedBox(height: 20),

                // Column Headers
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    _h('النوع', flex: 1),
                    _h('الصنف', flex: 2),
                    _h('الوزن', flex: 2),
                    _h('السعر/كجم', flex: 2),
                    _h('الإجمالي', flex: 2),
                    _h('الربح', flex: 2),
                    _h('التاريخ', flex: 2),
                  ]),
                ),
                const SizedBox(height: 8),

                // List
                Expanded(
                  child: list.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.receipt_long_outlined,
                                  size: 64, color: AppColors.textHint),
                              const SizedBox(height: 12),
                              Text('لا توجد عمليات',
                                  style: GoogleFonts.cairo(
                                      color: AppColors.textHint, fontSize: 16)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 5),
                          itemBuilder: (_, i) => _TxItem(t: list[i], fmt: fmt),
                        ),
                ),

                // Totals footer
                if (list.isNotEmpty) ...[
                  const Divider(height: 24),
                  _buildTotals(list, fmt),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _FilterChip(String label, String value, IconData icon) {
    final active = _filter == value;
    final color  = value == 'buy' ? AppColors.info
        : value == 'sell' ? AppColors.profit
        : AppColors.primary;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.15) : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: active ? color.withOpacity(0.5) : AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: active ? color : AppColors.textSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: GoogleFonts.cairo(
                    fontSize: 13,
                    color: active ? color : AppColors.textSecondary,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _h(String text, {int flex = 1}) => Expanded(
        flex: flex,
        child: Text(text,
            style: GoogleFonts.cairo(
                fontSize: 12, fontWeight: FontWeight.bold,
                color: AppColors.textSecondary)),
      );

  Widget _buildTotals(List<ScrapTransaction> list, NumberFormat fmt) {
    final totalSales     = list.where((t) => t.isSell).fold(0.0, (s, t) => s + t.totalPrice);
    final totalPurchases = list.where((t) => t.isBuy).fold(0.0, (s, t) => s + t.totalPrice);
    final netProfit      = list.where((t) => t.isSell).fold(0.0, (s, t) => s + t.netProfit);
    return Row(
      children: [
        _totalChip('إجمالي المبيعات', '${fmt.format(totalSales)} ج', AppColors.profit),
        const SizedBox(width: 12),
        _totalChip('إجمالي المشتريات', '${fmt.format(totalPurchases)} ج', AppColors.info),
        const SizedBox(width: 12),
        _totalChip('صافي الربح', '${fmt.format(netProfit)} ج',
            netProfit >= 0 ? AppColors.gold : AppColors.loss),
      ],
    );
  }

  Widget _totalChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.cairo(
                fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }
}

class _TxItem extends StatelessWidget {
  final ScrapTransaction t;
  final NumberFormat fmt;
  const _TxItem({required this.t, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final isBuy  = t.isBuy;
    final color  = isBuy ? AppColors.info : AppColors.profit;
    final dateStr = '${t.date.day}/${t.date.month}/${t.date.year}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Type
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isBuy ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    size: 13, color: color,
                  ),
                  const SizedBox(width: 4),
                  Text(t.typeAr,
                      style: GoogleFonts.cairo(
                          fontSize: 12, color: color, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          Expanded(flex: 2, child: Text(t.productName,
              style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textPrimary))),
          Expanded(flex: 2, child: Text(
              t.weight >= 1000 ? '${fmt.format(t.weightTons)} طن' : '${fmt.format(t.weight)} كجم',
              style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textPrimary))),
          Expanded(flex: 2, child: Text('${fmt.format(t.unitPrice)} ج',
              style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textSecondary))),
          Expanded(flex: 2, child: Text('${fmt.format(t.totalPrice)} ج',
              style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600, color: color))),
          Expanded(
            flex: 2,
            child: t.isSell
                ? Text('${fmt.format(t.netProfit)} ج',
                    style: GoogleFonts.cairo(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: t.netProfit >= 0 ? AppColors.profit : AppColors.loss))
                : Text('-', style: GoogleFonts.cairo(color: AppColors.textHint, fontSize: 13)),
          ),
          Expanded(flex: 2, child: Text(dateStr,
              style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary))),
        ],
      ),
    );
  }
}
