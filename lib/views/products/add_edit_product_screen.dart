import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../services/app_state.dart';
import '../../models/product_model.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product;
  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name, _buy, _sell, _stock, _minAlert;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name     = TextEditingController(text: p?.name ?? '');
    _buy      = TextEditingController(text: p != null ? p.buyPrice.toString() : '');
    _sell     = TextEditingController(text: p != null ? p.sellPrice.toString() : '');
    _stock    = TextEditingController(text: p != null ? p.currentStock.toString() : '0');
    _minAlert = TextEditingController(text: p != null ? p.minStockAlert.toString() : '100');
  }

  @override
  void dispose() {
    _name.dispose(); _buy.dispose(); _sell.dispose();
    _stock.dispose(); _minAlert.dispose();
    super.dispose();
  }

  double? _buyVal;
  double? _sellVal;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            onChanged: () => setState(() {
              _buyVal  = double.tryParse(_buy.text);
              _sellVal = double.tryParse(_sell.text);
            }),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Icon(_isEdit ? Icons.edit_rounded : Icons.add_rounded,
                        color: AppColors.primary, size: 22),
                    const SizedBox(width: 10),
                    Text(_isEdit ? 'تعديل الصنف' : 'إضافة صنف جديد',
                        style: GoogleFonts.cairo(
                            fontSize: 18, fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Name
                _field(
                  controller: _name,
                  label: 'اسم الصنف',
                  hint: 'مثال: حديد، نحاس، كرتون...',
                  icon: Icons.category_rounded,
                  validator: (v) => (v == null || v.isEmpty) ? 'الاسم مطلوب' : null,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _field(
                        controller: _buy,
                        label: 'سعر الشراء (ج/كجم)',
                        hint: '0.00',
                        icon: Icons.arrow_downward_rounded,
                        iconColor: AppColors.info,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'مطلوب';
                          if (double.tryParse(v) == null) return 'رقم غير صحيح';
                          if (double.parse(v) <= 0) return 'يجب أن يكون > 0';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        controller: _sell,
                        label: 'سعر البيع (ج/كجم)',
                        hint: '0.00',
                        icon: Icons.arrow_upward_rounded,
                        iconColor: AppColors.profit,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'مطلوب';
                          if (double.tryParse(v) == null) return 'رقم غير صحيح';
                          if (double.parse(v) <= 0) return 'يجب أن يكون > 0';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                // Margin preview
                if (_buyVal != null && _sellVal != null && _buyVal! > 0 && _sellVal! > 0) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: (_sellVal! > _buyVal! ? AppColors.profit : AppColors.loss).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: (_sellVal! > _buyVal! ? AppColors.profit : AppColors.loss).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _sellVal! > _buyVal! ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          color: _sellVal! > _buyVal! ? AppColors.profit : AppColors.loss,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'هامش الربح: ${(_sellVal! - _buyVal!).toStringAsFixed(2)} ج/كجم'
                          ' (${((_sellVal! - _buyVal!) / _buyVal! * 100).toStringAsFixed(1)}%)',
                          style: GoogleFonts.cairo(
                            color: _sellVal! > _buyVal! ? AppColors.profit : AppColors.loss,
                            fontSize: 13, fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        controller: _stock,
                        label: 'المخزون الحالي (كجم)',
                        hint: '0',
                        icon: Icons.inventory_2_rounded,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'مطلوب';
                          if (double.tryParse(v) == null) return 'رقم غير صحيح';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(
                        controller: _minAlert,
                        label: 'حد التنبيه (كجم)',
                        hint: '100',
                        icon: Icons.warning_amber_rounded,
                        iconColor: AppColors.warning,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'مطلوب';
                          if (double.tryParse(v) == null) return 'رقم غير صحيح';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('إلغاء', style: GoogleFonts.cairo()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _save,
                        child: Text(_isEdit ? 'حفظ التعديلات' : 'إضافة الصنف',
                            style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    Color? iconColor,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: GoogleFonts.cairo(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: iconColor ?? AppColors.textHint)
            : null,
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final state = context.read<AppState>();
    if (_isEdit) {
      state.updateProduct(widget.product!.copyWith(
        name: _name.text.trim(),
        buyPrice: double.parse(_buy.text),
        sellPrice: double.parse(_sell.text),
        currentStock: double.parse(_stock.text),
        minStockAlert: double.parse(_minAlert.text),
      ));
    } else {
      state.addProduct(
        name: _name.text.trim(),
        buyPrice: double.parse(_buy.text),
        sellPrice: double.parse(_sell.text),
        currentStock: double.parse(_stock.text),
        minStockAlert: double.parse(_minAlert.text),
      );
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_isEdit ? 'تم تعديل الصنف بنجاح' : 'تم إضافة الصنف بنجاح',
          style: GoogleFonts.cairo()),
      backgroundColor: AppColors.profit,
    ));
  }
}
