import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../services/app_state.dart';
import '../../models/transaction_model.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final fmt = NumberFormat('#,##0.##');
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, state),
                const SizedBox(height: 24),
                _buildStatCards(state, fmt),
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: _buildRecentTransactions(state, fmt),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          _buildStockSummary(state, fmt),
                          if (state.lowStockProducts.isNotEmpty ||
                              state.outOfStockProducts.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildAlerts(state),
                          ],
                        ],
                      ),
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

  // ─────────────────── Header ───────────────────
  Widget _buildHeader(BuildContext context, AppState state) {
    final now    = DateTime.now();
    final dayMap = {1:'الإثنين',2:'الثلاثاء',3:'الأربعاء',4:'الخميس',5:'الجمعة',6:'السبت',7:'الأحد'};
    final monMap = {1:'يناير',2:'فبراير',3:'مارس',4:'أبريل',5:'مايو',6:'يونيو',7:'يوليو',8:'أغسطس',9:'سبتمبر',10:'أكتوبر',11:'نوفمبر',12:'ديسمبر'};
    final dateStr = '${dayMap[now.weekday]}، ${now.day} ${monMap[now.month]} ${now.year}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('لوحة التحكم',
                style: GoogleFonts.cairo(
                    fontSize: 28, fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            Text(dateStr,
                style: GoogleFonts.cairo(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
        Row(
          children: [
            _QuickBtn(
              icon: Icons.shopping_cart_rounded,
              label: 'تسجيل شراء',
              color: AppColors.info,
              onTap: () => state.navigateTo(1),
            ),
            const SizedBox(width: 12),
            _QuickBtn(
              icon: Icons.sell_rounded,
              label: 'تسجيل بيع',
              color: AppColors.profit,
              onTap: () => state.navigateTo(2),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────── Stat Cards ───────────────────
  Widget _buildStatCards(AppState state, NumberFormat fmt) {
    return Row(
      children: [
        Expanded(child: _StatCard(
          title: 'رأس المال (الخزنة)',
          value: '${fmt.format(state.capitalBalance)} ج',
          icon: Icons.account_balance_wallet_rounded,
          color: AppColors.gold,
          subtitle: 'إجمالي رأس المال',
        )),
        const SizedBox(width: 16),
        Expanded(child: _StatCard(
          title: 'مبيعات اليوم',
          value: '${fmt.format(state.todaySales)} ج',
          icon: Icons.trending_up_rounded,
          color: AppColors.profit,
          subtitle: '${state.todayTransactions.where((t) => t.isSell).length} عملية بيع',
        )),
        const SizedBox(width: 16),
        Expanded(child: _StatCard(
          title: 'مشتريات اليوم',
          value: '${fmt.format(state.todayPurchases)} ج',
          icon: Icons.trending_down_rounded,
          color: AppColors.info,
          subtitle: '${state.todayTransactions.where((t) => t.isBuy).length} عملية شراء',
        )),
        const SizedBox(width: 16),
        Expanded(child: _StatCard(
          title: 'أرباح اليوم',
          value: '${fmt.format(state.todayProfit)} ج',
          icon: Icons.monetization_on_rounded,
          color: state.todayProfit >= 0 ? AppColors.profit : AppColors.loss,
          subtitle: state.todayProfit >= 0 ? 'ربح صافي' : 'خسارة',
        )),
      ],
    );
  }

  // ─────────────────── Recent Transactions ───────────────────
  Widget _buildRecentTransactions(AppState state, NumberFormat fmt) {
    final recent = state.recentTransactions;
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
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('آخر العمليات',
                    style: GoogleFonts.cairo(
                        fontSize: 16, fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                TextButton(
                  onPressed: () => state.navigateTo(5),
                  child: Text('عرض الكل',
                      style: GoogleFonts.cairo(color: AppColors.primary, fontSize: 13)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Text('لا توجد عمليات بعد',
                    style: GoogleFonts.cairo(color: AppColors.textHint)),
              ),
            )
          else
            ...recent.take(8).map((t) => _TxRow(t: t, fmt: fmt)),
        ],
      ),
    );
  }

  // ─────────────────── Stock Summary ───────────────────
  Widget _buildStockSummary(AppState state, NumberFormat fmt) {
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('المخزون الحالي',
                    style: GoogleFonts.cairo(
                        fontSize: 16, fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                Text('قيمة: ${fmt.format(state.totalStockValue)} ج',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: AppColors.gold)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...state.products.map((p) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: p.isOutOfStock ? AppColors.loss
                        : p.isLowStock ? AppColors.warning
                        : AppColors.profit,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(p.name,
                      style: GoogleFonts.cairo(
                          fontSize: 13, color: AppColors.textPrimary)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(p.currentStock >= 1000
                        ? '${fmt.format(p.currentStockTons)} طن'
                        : '${fmt.format(p.currentStock)} كجم',
                        style: GoogleFonts.cairo(
                            fontSize: 13, fontWeight: FontWeight.bold,
                            color: p.isOutOfStock ? AppColors.loss
                                : p.isLowStock ? AppColors.warning
                                : AppColors.textPrimary)),
                    Text('${fmt.format(p.stockValue)} ج',
                        style: GoogleFonts.cairo(
                            fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          )),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  // ─────────────────── Alerts ───────────────────
  Widget _buildAlerts(AppState state) {
    final alerts = [
      ...state.outOfStockProducts.map((p) => (p.name, 'نفد المخزون', AppColors.loss)),
      ...state.lowStockProducts.map((p) => (p.name, 'مخزون منخفض', AppColors.warning)),
    ];
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.warning, size: 18),
                const SizedBox(width: 8),
                Text('تنبيهات المخزون',
                    style: GoogleFonts.cairo(
                        fontSize: 15, fontWeight: FontWeight.bold,
                        color: AppColors.warning)),
              ],
            ),
          ),
          const Divider(height: 1),
          ...alerts.map((a) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.circle, size: 8, color: a.$3),
                const SizedBox(width: 10),
                Expanded(child: Text(a.$1,
                    style: GoogleFonts.cairo(
                        fontSize: 13, color: AppColors.textPrimary))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: a.$3.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: a.$3.withOpacity(0.4)),
                  ),
                  child: Text(a.$2,
                      style: GoogleFonts.cairo(
                          fontSize: 11, color: a.$3, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          )),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ─────────────────── Widgets ───────────────────
class _StatCard extends StatelessWidget {
  final String title, value, subtitle;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.title, required this.value, required this.subtitle,
    required this.icon, required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: GoogleFonts.cairo(
                      fontSize: 13, color: AppColors.textSecondary)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: GoogleFonts.cairo(
                  fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: GoogleFonts.cairo(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _TxRow extends StatelessWidget {
  final ScrapTransaction t;
  final NumberFormat fmt;
  const _TxRow({required this.t, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final isBuy = t.isBuy;
    final color = isBuy ? AppColors.info : AppColors.profit;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isBuy ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: color, size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.productName,
                    style: GoogleFonts.cairo(
                        fontSize: 13, fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                Text(
                  '${t.typeAr} • ${fmt.format(t.weight)} كجم • ${fmt.format(t.unitPrice)} ج/كجم',
                  style: GoogleFonts.cairo(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${fmt.format(t.totalPrice)} ج',
                  style: GoogleFonts.cairo(
                      fontSize: 14, fontWeight: FontWeight.bold, color: color)),
              if (t.isSell)
                Text('ربح: ${fmt.format(t.netProfit)} ج',
                    style: GoogleFonts.cairo(
                        fontSize: 11, color: AppColors.profit)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(label,
                  style: GoogleFonts.cairo(
                      color: color, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}