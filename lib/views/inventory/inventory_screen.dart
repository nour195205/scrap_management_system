import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../app_theme.dart';
import '../../services/app_state.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##');
    return Consumer<AppState>(
      builder: (context, state, _) {
        final products = state.products;
        final totalValue = state.totalStockValue;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Padding(
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
                          Text('المخزون الحالي',
                              style: GoogleFonts.cairo(
                                  fontSize: 26, fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                          Text('${products.length} صنف • إجمالي القيمة: ${fmt.format(totalValue)} جنيه',
                              style: GoogleFonts.cairo(
                                  fontSize: 13, color: AppColors.gold)),
                        ],
                      ),
                    ),
                    // Alert badges
                    if (state.outOfStockProducts.isNotEmpty)
                      _badge('${state.outOfStockProducts.length} نفد', AppColors.loss),
                    if (state.lowStockProducts.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      _badge('${state.lowStockProducts.length} منخفض', AppColors.warning),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // Summary cards
                Row(
                  children: List.generate(products.length, (index) {
                    final p = products[index];
                    final color = p.isOutOfStock ? AppColors.loss
                        : p.isLowStock ? AppColors.warning
                        : AppColors.profit;
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(left: index < products.length - 1 ? 12 : 0),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: color.withOpacity(0.35)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(p.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.cairo(
                                          fontSize: 13, fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary)),
                                ),
                                Container(
                                  width: 10, height: 10,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle, color: color),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              p.currentStock >= 1000
                                  ? '${fmt.format(p.currentStockTons)} طن'
                                  : '${fmt.format(p.currentStock)} كجم',
                              style: GoogleFonts.cairo(
                                  fontSize: 18, fontWeight: FontWeight.bold, color: color),
                            ),
                            Text('${fmt.format(p.stockValue)} ج',
                                style: GoogleFonts.cairo(
                                    fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 8),
                            // Progress bar with explicit constraints
                            LayoutBuilder(
                              builder: (context, constraints) => SizedBox(
                                width: constraints.maxWidth,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: p.minStockAlert > 0
                                        ? (p.currentStock / (p.minStockAlert * 3)).clamp(0, 1)
                                        : 1,
                                    backgroundColor: AppColors.surface,
                                    color: color,
                                    minHeight: 4,
                                  ),
                                ),
                              ),
                            ),
                            if (p.isLowStock || p.isOutOfStock) ...[
                              const SizedBox(height: 6),
                              Text(
                                p.isOutOfStock ? '⚠ نفد المخزون'
                                    : '⚠ أقل من ${fmt.format(p.minStockAlert)} كجم',
                                style: GoogleFonts.cairo(
                                    fontSize: 11, color: color,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),

                // Detail Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    _h('الصنف', flex: 2),
                    _h('المخزون (كجم)', flex: 2),
                    _h('المخزون (طن)', flex: 2),
                    _h('سعر الشراء', flex: 2),
                    _h('سعر البيع', flex: 2),
                    _h('قيمة المخزون', flex: 2),
                    _h('حد التنبيه', flex: 2),
                    _h('الحالة', flex: 2),
                  ]),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: ListView.separated(
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 5),
                    itemBuilder: (_, i) => _InventoryRow(product: products[i], fmt: fmt),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Text(text,
            style: GoogleFonts.cairo(
                fontSize: 13, color: color, fontWeight: FontWeight.bold)),
      );

  Widget _h(String text, {int flex = 1}) => Expanded(
        flex: flex,
        child: Text(text,
            style: GoogleFonts.cairo(
                fontSize: 12, fontWeight: FontWeight.bold,
                color: AppColors.textSecondary)),
      );
}

class _InventoryRow extends StatelessWidget {
  final dynamic product;
  final NumberFormat fmt;
  const _InventoryRow({required this.product, required this.fmt});

  @override
  Widget build(BuildContext context) {
    final p = product;
    final statusColor = p.isOutOfStock ? AppColors.loss
        : p.isLowStock ? AppColors.warning
        : AppColors.profit;
    final statusText  = p.isOutOfStock ? 'نفد' : p.isLowStock ? 'منخفض' : 'ممتاز';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (p.isOutOfStock || p.isLowStock)
              ? statusColor.withOpacity(0.3)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(p.name,
              style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary))),
          Expanded(flex: 2, child: Text(fmt.format(p.currentStock),
              style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textPrimary))),
          Expanded(flex: 2, child: Text(fmt.format(p.currentStockTons),
              style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textPrimary))),
          Expanded(flex: 2, child: Text('${fmt.format(p.buyPrice)} ج',
              style: GoogleFonts.cairo(fontSize: 13, color: AppColors.info))),
          Expanded(flex: 2, child: Text('${fmt.format(p.sellPrice)} ج',
              style: GoogleFonts.cairo(fontSize: 13, color: AppColors.profit))),
          Expanded(flex: 2, child: Text('${fmt.format(p.stockValue)} ج',
              style: GoogleFonts.cairo(fontSize: 13, fontWeight: FontWeight.w600,
                  color: AppColors.gold))),
          Expanded(flex: 2, child: Text('${fmt.format(p.minStockAlert)} كجم',
              style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textSecondary))),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(statusText,
                  style: GoogleFonts.cairo(
                      fontSize: 12, color: statusColor, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
