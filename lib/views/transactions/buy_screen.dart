import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../app_theme.dart';
import '../../services/app_state.dart';
import '../../models/product_model.dart';

class BuyScreen extends StatefulWidget {
  const BuyScreen({super.key});
  @override
  State<BuyScreen> createState() => _BuyScreenState();
}

class _BuyScreenState extends State<BuyScreen> {
  final _formKey = GlobalKey<FormState>();
  Product? _selectedProduct;
  final _weightCtrl = TextEditingController();
  final _priceCtrl  = TextEditingController();
  final _notesCtrl  = TextEditingController();
  bool _weightInTons = false;

  double get _weightKg {
    final v = double.tryParse(_weightCtrl.text) ?? 0;
    return _weightInTons ? v * 1000 : v;
  }

  double get _unitPrice => double.tryParse(_priceCtrl.text) ?? 0;
  double get _total => _weightKg * _unitPrice;

  @override
  void dispose() {
    _weightCtrl.dispose(); _priceCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.##');
    return Consumer<AppState>(
      builder: (context, state, _) {
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
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shopping_cart_rounded,
                          color: AppColors.info, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('تسجيل مشتريات',
                            style: GoogleFonts.cairo(
                                fontSize: 26, fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                        Text('الشراء يُخصم من الخزنة ويُضاف للمخزون',
                            style: GoogleFonts.cairo(
                                fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Form ──
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Form(
                          key: _formKey,
                          onChanged: () => setState(() {}),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('بيانات الشراء',
                                  style: GoogleFonts.cairo(
                                      fontSize: 16, fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary)),
                              const SizedBox(height: 20),

                              // Product selector
                              DropdownButtonFormField<Product>(
                                value: _selectedProduct,
                                decoration: InputDecoration(
                                  labelText: 'اختر الصنف',
                                  prefixIcon: const Icon(Icons.category_rounded,
                                      size: 18, color: AppColors.textHint),
                                ),
                                dropdownColor: AppColors.card,
                                style: GoogleFonts.cairo(
                                    color: AppColors.textPrimary, fontSize: 14),
                                items: state.products
                                    .map((p) => DropdownMenuItem(
                                          value: p,
                                          child: Text(p.name,
                                              style: GoogleFonts.cairo(
                                                  color: AppColors.textPrimary)),
                                        ))
                                    .toList(),
                                onChanged: (p) => setState(() {
                                  _selectedProduct = p;
                                  if (p != null) {
                                    _priceCtrl.text = p.buyPrice.toString();
                                  }
                                }),
                                validator: (v) => v == null ? 'اختر صنف' : null,
                              ),
                              const SizedBox(height: 16),

                              // Weight + unit toggle
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _weightCtrl,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                                      style: GoogleFonts.cairo(
                                          color: AppColors.textPrimary, fontSize: 14),
                                      decoration: InputDecoration(
                                        labelText: 'الوزن',
                                        hintText: '0.00',
                                        prefixIcon: const Icon(Icons.scale_rounded,
                                            size: 18, color: AppColors.textHint),
                                        suffixText: _weightInTons ? 'طن' : 'كجم',
                                        suffixStyle: GoogleFonts.cairo(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.isEmpty) return 'الوزن مطلوب';
                                        if ((double.tryParse(v) ?? 0) <= 0) return 'يجب أن يكون > 0';
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Unit toggle
                                  Column(
                                    children: [
                                      const SizedBox(height: 4),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.surface,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: AppColors.border),
                                        ),
                                        child: Row(
                                          children: [
                                            _unitBtn('كجم', !_weightInTons,
                                                () => setState(() => _weightInTons = false)),
                                            _unitBtn('طن ', _weightInTons,
                                                () => setState(() => _weightInTons = true)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              // Weight conversion hint
                              if (_weightCtrl.text.isNotEmpty &&
                                  (double.tryParse(_weightCtrl.text) ?? 0) > 0) ...[
                                const SizedBox(height: 6),
                                Text(
                                  _weightInTons
                                      ? '= ${fmt.format(_weightKg)} كجم'
                                      : '= ${fmt.format(_weightKg / 1000)} طن',
                                  style: GoogleFonts.cairo(
                                      fontSize: 12, color: AppColors.primary),
                                ),
                              ],

                              const SizedBox(height: 16),

                              // Unit price
                              TextFormField(
                                controller: _priceCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                                style: GoogleFonts.cairo(
                                    color: AppColors.textPrimary, fontSize: 14),
                                decoration: const InputDecoration(
                                  labelText: 'سعر الشراء (ج/كجم)',
                                  hintText: '0.00',
                                  prefixIcon: Icon(Icons.monetization_on_rounded,
                                      size: 18, color: AppColors.textHint),
                                  suffixText: 'ج/كجم',
                                ),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'السعر مطلوب';
                                  if ((double.tryParse(v) ?? 0) <= 0) return 'يجب أن يكون > 0';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Notes
                              TextFormField(
                                controller: _notesCtrl,
                                style: GoogleFonts.cairo(
                                    color: AppColors.textPrimary, fontSize: 14),
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'ملاحظات (اختياري)',
                                  hintText: 'اسم المورد، تفاصيل...',
                                  prefixIcon: Icon(Icons.notes_rounded,
                                      size: 18, color: AppColors.textHint),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 20),

                    // ── Summary ──
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildSummary(state, fmt),
                          const SizedBox(height: 16),
                          _buildCapitalPreview(state, fmt),
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

  Widget _buildSummary(AppState state, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_rounded, color: AppColors.info, size: 18),
              const SizedBox(width: 8),
              Text('ملخص العملية',
                  style: GoogleFonts.cairo(
                      fontSize: 15, fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 20),
          _summaryRow('الصنف', _selectedProduct?.name ?? '-', AppColors.textPrimary),
          _summaryRow('الوزن',
              _weightCtrl.text.isEmpty ? '-' : '${fmt.format(_weightKg)} كجم',
              AppColors.textPrimary),
          _summaryRow('السعر',
              _priceCtrl.text.isEmpty ? '-' : '${fmt.format(_unitPrice)} ج/كجم',
              AppColors.textPrimary),
          const Divider(height: 24),
          _summaryRow(
            'الإجمالي',
            _total > 0 ? '${fmt.format(_total)} جنيه' : '-',
            AppColors.info,
            bold: true, large: true,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.info,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 20),
              label: Text('تأكيد الشراء',
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapitalPreview(AppState state, NumberFormat fmt) {
    final newBalance = state.capitalBalance - _total;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _summaryRow('رصيد الخزنة الحالي',
              '${fmt.format(state.capitalBalance)} ج', AppColors.gold),
          const SizedBox(height: 8),
          _summaryRow('بعد الشراء',
              '${fmt.format(newBalance)} ج',
              newBalance >= 0 ? AppColors.profit : AppColors.loss),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color valueColor,
      {bool bold = false, bool large = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.cairo(
                  fontSize: 13, color: AppColors.textSecondary)),
          Text(value,
              style: GoogleFonts.cairo(
                  fontSize: large ? 18 : 14,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                  color: valueColor)),
        ],
      ),
    );
  }

  Widget _unitBtn(String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(text,
            style: GoogleFonts.cairo(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: active ? Colors.black87 : AppColors.textSecondary)),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final error = context.read<AppState>().registerBuy(
      productId: _selectedProduct!.id,
      weightKg: _weightKg,
      unitPricePerKg: _unitPrice,
      notes: _notesCtrl.text.isNotEmpty ? _notesCtrl.text : null,
    );
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error, style: GoogleFonts.cairo()),
        backgroundColor: AppColors.loss,
      ));
      return;
    }
    // Reset form
    setState(() {
      _selectedProduct = null;
      _weightCtrl.clear();
      _priceCtrl.clear();
      _notesCtrl.clear();
      _weightInTons = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✅ تم تسجيل الشراء بنجاح', style: GoogleFonts.cairo()),
      backgroundColor: AppColors.profit,
    ));
  }
}
