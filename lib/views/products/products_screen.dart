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
      builder: (ctx) => Dialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.loss.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_forever_rounded,
                    color: AppColors.loss, size: 32),
              ),
              const SizedBox(height: 16),
              Text('تأكيد حذف الصنف',
                  style: GoogleFonts.cairo(
                      fontSize: 20, fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'هل تريد حذف صنف "${product.name}"؟',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                    fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                ),
                child: Text(
                  '⚠️ لا يمكن الحذف إذا كان هناك عمليات مرتبطة بهذا الصنف',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                      fontSize: 12, color: AppColors.warning),
                ),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Text('إلغاء',
                        style: GoogleFonts.cairo(color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final ok = await state.deleteProduct(product.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                            ok
                              ? '🗑️ تم حذف "${product.name}" بنجاح'
                              : 'لا يمكن الحذف - يوجد عمليات مرتبطة بهذا الصنف',
                            style: GoogleFonts.cairo(),
                          ),
                          backgroundColor: ok ? AppColors.gold : AppColors.loss,
                        ));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.loss,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.delete_rounded, size: 18),
                    label: Text('نعم، احذف',
                        style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductRow extends StatefulWidget {
  final Product product;
  final NumberFormat fmt;
  final VoidCallback onEdit, onDelete;
  const _ProductRow({
    required this.product,
    required this.fmt,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends State<_ProductRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final fmt     = widget.fmt;
    final statusColor = product.isOutOfStock ? AppColors.loss
        : product.isLowStock ? AppColors.warning
        : AppColors.profit;
    final borderColor = product.isOutOfStock ? AppColors.loss.withOpacity(0.4)
        : product.isLowStock ? AppColors.warning.withOpacity(0.4)
        : _hovered ? AppColors.primary.withOpacity(0.3)
        : AppColors.border;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.surface : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            // Name + status dot
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(product.name,
                      style: GoogleFonts.cairo(
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
                          fontSize: 10, color: statusColor),
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
              child: AnimatedOpacity(
                opacity: _hovered ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 150),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _iconBtn(
                      icon: Icons.edit_rounded,
                      color: AppColors.primary,
                      tooltip: 'تعديل',
                      onTap: widget.onEdit,
                    ),
                    const SizedBox(width: 4),
                    _iconBtn(
                      icon: Icons.delete_rounded,
                      color: AppColors.loss,
                      tooltip: 'حذف',
                      onTap: widget.onDelete,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}
