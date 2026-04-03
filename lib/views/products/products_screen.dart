import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../app_theme.dart';
import '../../services/app_state.dart';
import '../../models/product_model.dart';
import 'add_edit_product_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});
  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##');
    return Consumer<AppState>(
      builder: (context, state, _) {
        final products = state.products
            .where((p) => p.name.contains(_search))
            .toList();

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
                          Text('الأصناف',
                              style: GoogleFonts.cairo(
                                  fontSize: 26, fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                          Text('${state.products.length} صنف مسجل',
                              style: GoogleFonts.cairo(
                                  fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _openForm(context),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: Text('إضافة صنف', style: GoogleFonts.cairo()),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Search
                TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: GoogleFonts.cairo(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'بحث عن صنف...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            onPressed: () => setState(() => _search = ''),
                            icon: const Icon(Icons.close, color: AppColors.textHint, size: 18),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 20),

                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _hdr('الصنف', flex: 3),
                      _hdr('سعر الشراء (كجم)', flex: 2),
                      _hdr('سعر البيع (كجم)', flex: 2),
                      _hdr('المخزون', flex: 2),
                      _hdr('هامش الربح', flex: 2),
                      _hdr('', flex: 1),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // List
                Expanded(
                  child: products.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.category_outlined,
                                  size: 64, color: AppColors.textHint),
                              const SizedBox(height: 16),
                              Text('لا توجد أصناف', style: GoogleFonts.cairo(
                                  color: AppColors.textHint, fontSize: 16)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: products.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (_, i) =>
                              _ProductRow(
                                product: products[i],
                                fmt: fmt,
                                onEdit: () => _openForm(context, product: products[i]),
                                onDelete: () => _confirmDelete(context, state, products[i]),
                              ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _hdr(String text, {int flex = 1}) => Expanded(
        flex: flex,
        child: Text(text,
            style: GoogleFonts.cairo(
                fontSize: 12, fontWeight: FontWeight.bold,
                color: AppColors.textSecondary)),
      );

  void _openForm(BuildContext context, {Product? product}) {
    showDialog(
      context: context,
      builder: (_) => AddEditProductScreen(product: product),
    );
  }

  void _confirmDelete(BuildContext context, AppState state, Product product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('حذف الصنف', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
        content: Text('هل تريد حذف صنف "${product.name}"؟',
            style: GoogleFonts.cairo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: GoogleFonts.cairo()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final ok = await state.deleteProduct(product.id);
              if (!ok) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('لا يمكن الحذف - يوجد عمليات مرتبطة بهذا الصنف',
                      style: GoogleFonts.cairo()),
                  backgroundColor: AppColors.loss,
                ));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.loss),
            child: Text('حذف', style: GoogleFonts.cairo()),
          ),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final Product product;
  final NumberFormat fmt;
  final VoidCallback onEdit, onDelete;
  const _ProductRow({required this.product, required this.fmt, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: product.isOutOfStock ? AppColors.loss.withOpacity(0.4)
              : product.isLowStock ? AppColors.warning.withOpacity(0.4)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Name
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: product.isOutOfStock ? AppColors.loss
                        : product.isLowStock ? AppColors.warning
                        : AppColors.profit,
                  ),
                ),
                const SizedBox(width: 10),
                Text(product.name, style: GoogleFonts.cairo(
                    fontSize: 14, fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
              ],
            ),
          ),
          // Buy price
          Expanded(flex: 2, child: Text('${fmt.format(product.buyPrice)} ج',
              style: GoogleFonts.cairo(color: AppColors.info, fontSize: 13))),
          // Sell price
          Expanded(flex: 2, child: Text('${fmt.format(product.sellPrice)} ج',
              style: GoogleFonts.cairo(color: AppColors.profit, fontSize: 13))),
          // Stock
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.currentStock >= 1000
                      ? '${fmt.format(product.currentStockTons)} طن'
                      : '${fmt.format(product.currentStock)} كجم',
                  style: GoogleFonts.cairo(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: product.isOutOfStock ? AppColors.loss
                          : product.isLowStock ? AppColors.warning
                          : AppColors.textPrimary),
                ),
                if (product.isLowStock || product.isOutOfStock)
                  Text(
                    product.isOutOfStock ? '⚠ نفد المخزون' : '⚠ منخفض',
                    style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: product.isOutOfStock ? AppColors.loss : AppColors.warning),
                  ),
              ],
            ),
          ),
          // Margin
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${fmt.format(product.margin)} ج/كجم',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                      fontSize: 12, color: AppColors.gold,
                      fontWeight: FontWeight.w600)),
                Text(
                  '${fmt.format(product.marginPercent)}%',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                      fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          // Actions
          SizedBox(
            width: 88,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
                  tooltip: 'تعديل',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.loss),
                  tooltip: 'حذف',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
