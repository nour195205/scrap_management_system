import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  String _search  = '';

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##');
    return Consumer<AppState>(
      builder: (context, state, _) {
        var list = state.getTransactions(
          type: _filter == 'buy'  ? TransactionType.buy
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
                // ── Header ───────────────────────────────────
                Text('سجل العمليات',
                    style: GoogleFonts.cairo(
                        fontSize: 26, fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                Text('${state.transactions.length} عملية مسجلة',
                    style: GoogleFonts.cairo(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 20),

                // ── Filters ───────────────────────────────────
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
                    _FilterChip('الكل',    'all',  Icons.list_rounded),
                    const SizedBox(width: 8),
                    _FilterChip('مشتريات', 'buy',  Icons.arrow_downward_rounded),
                    const SizedBox(width: 8),
                    _FilterChip('مبيعات',  'sell', Icons.arrow_upward_rounded),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Column Headers ────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(children: [
                    _h('النوع',      flex: 1),
                    _h('الصنف',      flex: 2),
                    _h('الوزن',      flex: 2),
                    _h('السعر/كجم',  flex: 2),
                    _h('الإجمالي',   flex: 2),
                    _h('الربح',      flex: 2),
                    _h('التاريخ',    flex: 2),
                    _h('',           flex: 1), // actions col header
                  ]),
                ),
                const SizedBox(height: 8),

                // ── List ──────────────────────────────────────
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
                          itemBuilder: (_, i) => _TxItem(
                            t: list[i],
                            fmt: fmt,
                            onEdit:   () => _showEditDialog(context, list[i]),
                            onDelete: () => _showDeleteConfirm(context, list[i]),
                          ),
                        ),
                ),

                // ── Totals footer ─────────────────────────────
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

  // ═══════════════════════════════════════════
  //  EDIT DIALOG
  // ═══════════════════════════════════════════
  void _showEditDialog(BuildContext context, ScrapTransaction tx) {
    final weightCtrl = TextEditingController(text: tx.weight.toString());
    final priceCtrl  = TextEditingController(text: tx.unitPrice.toString());
    final notesCtrl  = TextEditingController(text: tx.notes ?? '');
    final formKey    = GlobalKey<FormState>();
    final fmt        = NumberFormat('#,##0.##');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final newWeight = double.tryParse(weightCtrl.text) ?? 0;
          final newPrice  = double.tryParse(priceCtrl.text)  ?? 0;
          final newTotal  = newWeight * newPrice;
          final color     = tx.isBuy ? AppColors.info : AppColors.profit;

          return Dialog(
            backgroundColor: AppColors.card,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              width: 520,
              padding: const EdgeInsets.all(28),
              child: Form(
                key: formKey,
                onChanged: () => setDlgState(() {}),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.edit_rounded, color: color, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('تعديل عملية ${tx.typeAr}',
                                style: GoogleFonts.cairo(
                                    fontSize: 18, fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary)),
                            Text(tx.productName,
                                style: GoogleFonts.cairo(
                                    fontSize: 13, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // Weight Field
                    TextFormField(
                      controller: weightCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                      style: GoogleFonts.cairo(color: AppColors.textPrimary, fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: 'الوزن (كجم)',
                        prefixIcon: Icon(Icons.scale_rounded, size: 18, color: AppColors.textHint),
                        suffixText: 'كجم',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'الوزن مطلوب';
                        if ((double.tryParse(v) ?? 0) <= 0) return 'يجب أن يكون > 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Price Field
                    TextFormField(
                      controller: priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                      style: GoogleFonts.cairo(color: AppColors.textPrimary, fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: 'السعر (ج/كجم)',
                        prefixIcon: Icon(Icons.monetization_on_rounded, size: 18, color: AppColors.textHint),
                        suffixText: 'ج/كجم',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'السعر مطلوب';
                        if ((double.tryParse(v) ?? 0) <= 0) return 'يجب أن يكون > 0';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Notes Field
                    TextFormField(
                      controller: notesCtrl,
                      style: GoogleFonts.cairo(color: AppColors.textPrimary, fontSize: 14),
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'ملاحظات (اختياري)',
                        prefixIcon: Icon(Icons.notes_rounded, size: 18, color: AppColors.textHint),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Total Preview
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('الإجمالي الجديد:',
                              style: GoogleFonts.cairo(
                                  fontSize: 14, color: AppColors.textSecondary)),
                          Text(
                            newTotal > 0 ? '${fmt.format(newTotal)} جنيه' : '-',
                            style: GoogleFonts.cairo(
                                fontSize: 16, fontWeight: FontWeight.bold, color: color),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Buttons
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
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            Navigator.pop(ctx);
                            final error = await context.read<AppState>().updateTransaction(
                              transactionId: tx.id,
                              newWeightKg:   double.parse(weightCtrl.text),
                              newUnitPrice:  double.parse(priceCtrl.text),
                              newNotes: notesCtrl.text.isNotEmpty ? notesCtrl.text : null,
                            );
                            if (error != null && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(error, style: GoogleFonts.cairo()),
                                backgroundColor: AppColors.loss,
                              ));
                            } else if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('✅ تم تعديل العملية بنجاح', style: GoogleFonts.cairo()),
                                backgroundColor: AppColors.profit,
                              ));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(Icons.check_circle_rounded, size: 18),
                          label: Text('حفظ التعديل',
                              style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  DELETE CONFIRM DIALOG
  // ═══════════════════════════════════════════
  void _showDeleteConfirm(BuildContext context, ScrapTransaction tx) {
    final fmt = NumberFormat('#,##0.##');
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
              Text('تأكيد الحذف',
                  style: GoogleFonts.cairo(
                      fontSize: 20, fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'هل تريد حذف عملية ${tx.typeAr} للصنف "${tx.productName}"؟\n'
                'الوزن: ${fmt.format(tx.weight)} كجم | الإجمالي: ${fmt.format(tx.totalPrice)} ج',
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.loss.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.loss.withOpacity(0.25)),
                ),
                child: Text(
                  tx.isBuy
                      ? '⚠️ سيتم خصم ${fmt.format(tx.weight)} كجم من المخزون وإعادة ${fmt.format(tx.totalPrice)} ج للخزنة'
                      : '⚠️ سيتم إلغاء ${fmt.format(tx.totalPrice)} ج من الخزنة وإعادة ${fmt.format(tx.weight)} كجم للمخزون',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(fontSize: 12, color: AppColors.loss),
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
                      final error = await context.read<AppState>().deleteTransaction(tx.id);
                      if (error != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(error, style: GoogleFonts.cairo()),
                          backgroundColor: AppColors.loss,
                        ));
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('🗑️ تم حذف العملية بنجاح', style: GoogleFonts.cairo()),
                          backgroundColor: AppColors.gold,
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

  // ═══════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════
  Widget _FilterChip(String label, String value, IconData icon) {
    final active = _filter == value;
    final color  = value == 'buy'  ? AppColors.info
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
        _totalChip('إجمالي المبيعات',   '${fmt.format(totalSales)} ج',     AppColors.profit),
        const SizedBox(width: 12),
        _totalChip('إجمالي المشتريات',  '${fmt.format(totalPurchases)} ج', AppColors.info),
        const SizedBox(width: 12),
        _totalChip('صافي الربح',         '${fmt.format(netProfit)} ج',
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

// ════════════════════════════════════════════════════════
//  TRANSACTION ROW WIDGET
// ════════════════════════════════════════════════════════
class _TxItem extends StatefulWidget {
  final ScrapTransaction t;
  final NumberFormat fmt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _TxItem({
    required this.t,
    required this.fmt,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_TxItem> createState() => _TxItemState();
}

class _TxItemState extends State<_TxItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final t      = widget.t;
    final fmt    = widget.fmt;
    final isBuy  = t.isBuy;
    final color  = isBuy ? AppColors.info : AppColors.profit;
    final dateStr = '${t.date.day}/${t.date.month}/${t.date.year}';

    return MouseRegion(
      onEnter:  (_) => setState(() => _hovered = true),
      onExit:   (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.surface : AppColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _hovered ? color.withOpacity(0.3) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            // Type badge
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
                t.weight >= 1000
                    ? '${fmt.format(t.weightTons)} طن'
                    : '${fmt.format(t.weight)} كجم',
                style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textPrimary))),
            Expanded(flex: 2, child: Text('${fmt.format(t.unitPrice)} ج',
                style: GoogleFonts.cairo(fontSize: 13, color: AppColors.textSecondary))),
            Expanded(flex: 2, child: Text('${fmt.format(t.totalPrice)} ج',
                style: GoogleFonts.cairo(
                    fontSize: 13, fontWeight: FontWeight.w600, color: color))),
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

            // Action buttons
            Expanded(
              flex: 1,
              child: AnimatedOpacity(
                opacity: _hovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
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
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 15, color: color),
        ),
      ),
    );
  }
}
