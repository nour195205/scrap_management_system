import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/capital_security_service.dart';
import '../../app_theme.dart';

/// حوار الإعداد الأول لكلمة مرور الخزنة
Future<bool> showCapitalSetupDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _CapitalSetupDialog(),
      ) ??
      false;
}

class _CapitalSetupDialog extends StatefulWidget {
  const _CapitalSetupDialog();
  @override
  State<_CapitalSetupDialog> createState() => _CapitalSetupDialogState();
}

class _CapitalSetupDialogState extends State<_CapitalSetupDialog>
    with SingleTickerProviderStateMixin {
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _answerCtrl  = TextEditingController();
  final _formKey     = GlobalKey<FormState>();

  bool _obscurePass    = true;
  bool _obscureConfirm = true;
  bool _obscureAnswer  = true;
  bool _loading        = false;
  String? _error;

  String _selectedQuestion =
      'ما هو اسم المدينة التي وُلدت فيها؟';

  final _questions = [
    'ما هو اسم المدينة التي وُلدت فيها؟',
    'ما هو اسم حيوانك الأليف الأول؟',
    'ما هو اسم مدرستك الابتدائية؟',
    'ما هو الطعام المفضل لديك؟',
    'ما هو اسم أحد والديك؟',
    'ما هي مهنتك الأولى؟',
  ];

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    await CapitalSecurityService().setupPassword(
      password: _passCtrl.text,
      question: _selectedQuestion,
      answer: _answerCtrl.text,
    );
    setState(() => _loading = false);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 480,
            constraints: const BoxConstraints(maxWidth: 480),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.gold.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.gold.withOpacity(0.08),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // أيقونة
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2C2000), Color(0xFF3D2E00)],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.gold.withOpacity(0.4), width: 2),
                      ),
                      child: const Icon(Icons.lock_rounded,
                          color: AppColors.gold, size: 34),
                    ),
                    const SizedBox(height: 20),

                    Text('تأمين الخزنة',
                        style: GoogleFonts.cairo(
                            fontSize: 22, fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    Text('قم بإعداد كلمة مرور لحماية قسم الخزنة',
                        style: GoogleFonts.cairo(
                            fontSize: 13, color: AppColors.textSecondary),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 28),

                    // ── كلمة المرور ──
                    _buildField(
                      controller: _passCtrl,
                      label: 'كلمة المرور',
                      hint: 'أدخل كلمة مرور قوية',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscurePass,
                      onToggleObscure: () =>
                          setState(() => _obscurePass = !_obscurePass),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'أدخل كلمة المرور';
                        if (v.length < 4) return 'يجب أن تكون 4 أحرف على الأقل';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // ── تأكيد كلمة المرور ──
                    _buildField(
                      controller: _confirmCtrl,
                      label: 'تأكيد كلمة المرور',
                      hint: 'أعد إدخال كلمة المرور',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscureConfirm,
                      onToggleObscure: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      validator: (v) {
                        if (v != _passCtrl.text) return 'كلمتا المرور غير متطابقتين';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── فاصل سؤال الأمان ──
                    Row(children: [
                      const Expanded(child: Divider(color: AppColors.border)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('سؤال الأمان (احتياطي)',
                            style: GoogleFonts.cairo(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ),
                      const Expanded(child: Divider(color: AppColors.border)),
                    ]),
                    const SizedBox(height: 14),

                    // ── اختيار السؤال ──
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedQuestion,
                          isExpanded: true,
                          dropdownColor: AppColors.card,
                          iconEnabledColor: AppColors.textSecondary,
                          style: GoogleFonts.cairo(
                              fontSize: 13, color: AppColors.textPrimary),
                          items: _questions
                              .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedQuestion = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── الإجابة ──
                    _buildField(
                      controller: _answerCtrl,
                      label: 'إجابة سؤال الأمان',
                      hint: 'اكتب إجابتك',
                      icon: Icons.help_outline_rounded,
                      obscure: _obscureAnswer,
                      onToggleObscure: () =>
                          setState(() => _obscureAnswer = !_obscureAnswer),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'أدخل إجابة سؤال الأمان';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text('  ⚠ احتفظ بهذه الإجابة، ستحتاجها لو نسيت كلمة المرور',
                          style: GoogleFonts.cairo(
                              fontSize: 11, color: AppColors.warning)),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.loss.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.loss.withOpacity(0.3)),
                        ),
                        child: Row(children: [
                          const Icon(Icons.error_outline, color: AppColors.loss, size: 16),
                          const SizedBox(width: 8),
                          Text(_error!,
                              style: GoogleFonts.cairo(
                                  color: AppColors.loss, fontSize: 13)),
                        ]),
                      ),
                    ],

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black54))
                            : Text('حفظ وتأمين الخزنة',
                                style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggleObscure,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.cairo(color: AppColors.textPrimary, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textHint),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            size: 18, color: AppColors.textHint,
          ),
          onPressed: onToggleObscure,
        ),
      ),
    );
  }
}
