import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/capital_security_service.dart';
import '../../app_theme.dart';

/// حوار تغيير كلمة مرور الخزنة
/// يتطلب الباسوورد القديم أو إجابة سؤال الأمان
Future<void> showCapitalChangePasswordDialog(BuildContext context) async {
  await showDialog<void>(
    context: context,
    builder: (_) => const _ChangePasswordDialog(),
  );
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();
  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  // ── controllers ───────────────────────────────────
  final _oldPassCtrl  = TextEditingController();
  final _answerCtrl   = TextEditingController();
  final _newPassCtrl  = TextEditingController();
  final _confirmCtrl  = TextEditingController();
  final _formKey      = GlobalKey<FormState>();

  // ── state ─────────────────────────────────────────
  bool _useQuestion  = false; // true = مصادقة بالسؤال
  bool _obscureOld   = true;
  bool _obscureNew   = true;
  bool _obscureConf  = true;
  bool _obscureAns   = true;
  bool _loading      = false;
  bool _success      = false;
  String? _error;
  String? _question;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    final q = await CapitalSecurityService().getSecurityQuestion();
    setState(() => _question = q);
  }

  @override
  void dispose() {
    _oldPassCtrl.dispose(); _answerCtrl.dispose();
    _newPassCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final ok = await CapitalSecurityService().changePassword(
      newPassword:    _newPassCtrl.text,
      oldPassword:    _useQuestion ? null : _oldPassCtrl.text,
      securityAnswer: _useQuestion ? _answerCtrl.text : null,
    );

    setState(() => _loading = false);

    if (ok) {
      setState(() => _success = true);
      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted) Navigator.of(context).pop();
    } else {
      setState(() => _error = _useQuestion
          ? 'إجابة سؤال الأمان خاطئة'
          : 'كلمة المرور القديمة غير صحيحة');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 460,
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 40, spreadRadius: 2,
            ),
          ],
        ),
        child: _success ? _buildSuccess() : _buildForm(),
      ),
    );
  }

  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded,
              color: AppColors.profit, size: 64),
          const SizedBox(height: 16),
          Text('تم تغيير كلمة المرور بنجاح',
              style: GoogleFonts.cairo(
                  fontSize: 18, fontWeight: FontWeight.bold,
                  color: AppColors.profit),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('الخزنة محمية الآن بكلمة المرور الجديدة',
              style: GoogleFonts.cairo(
                  fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── رأس الحوار ──
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.lock_reset_rounded,
                    color: AppColors.primary, size: 26),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('تغيير كلمة المرور',
                    style: GoogleFonts.cairo(
                        fontSize: 18, fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary)),
                Text('تحتاج التحقق من هويتك أولاً',
                    style: GoogleFonts.cairo(
                        fontSize: 12, color: AppColors.textSecondary)),
              ]),
            ]),
            const SizedBox(height: 24),

            // ── تبديل طريقة التحقق ──
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() { _useQuestion = false; _error = null; }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_useQuestion
                            ? AppColors.primary.withOpacity(0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: !_useQuestion
                            ? Border.all(color: AppColors.primary.withOpacity(0.4))
                            : null,
                      ),
                      child: Center(
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.lock_outline_rounded,
                              size: 16,
                              color: !_useQuestion
                                  ? AppColors.primary
                                  : AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text('كلمة المرور القديمة',
                              style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: !_useQuestion
                                      ? AppColors.primary
                                      : AppColors.textSecondary)),
                        ]),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() { _useQuestion = true; _error = null; }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _useQuestion
                            ? AppColors.gold.withOpacity(0.12)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: _useQuestion
                            ? Border.all(color: AppColors.gold.withOpacity(0.4))
                            : null,
                      ),
                      child: Center(
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.help_outline_rounded,
                              size: 16,
                              color: _useQuestion
                                  ? AppColors.gold
                                  : AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text('سؤال الأمان',
                              style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _useQuestion
                                      ? AppColors.gold
                                      : AppColors.textSecondary)),
                        ]),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 20),

            // ── حقل المصادقة ──
            if (!_useQuestion)
              _fieldRow(
                controller: _oldPassCtrl,
                label: 'كلمة المرور القديمة',
                icon: Icons.lock_outline_rounded,
                obscure: _obscureOld,
                onToggle: () => setState(() => _obscureOld = !_obscureOld),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'أدخل كلمة المرور القديمة';
                  return null;
                },
              )
            else ...[
              if (_question != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.help_outline_rounded,
                        color: AppColors.gold, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_question!,
                          style: GoogleFonts.cairo(
                              fontSize: 13, color: AppColors.textPrimary)),
                    ),
                  ]),
                ),
              const SizedBox(height: 12),
              _fieldRow(
                controller: _answerCtrl,
                label: 'إجابة سؤال الأمان',
                icon: Icons.help_outline_rounded,
                obscure: _obscureAns,
                onToggle: () => setState(() => _obscureAns = !_obscureAns),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'أدخل إجابة سؤال الأمان';
                  return null;
                },
              ),
            ],

            const SizedBox(height: 16),
            const Divider(color: AppColors.border),
            const SizedBox(height: 16),

            // ── كلمة المرور الجديدة ──
            _fieldRow(
              controller: _newPassCtrl,
              label: 'كلمة المرور الجديدة',
              icon: Icons.lock_rounded,
              obscure: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
              validator: (v) {
                if (v == null || v.isEmpty) return 'أدخل كلمة المرور الجديدة';
                if (v.length < 4) return 'يجب أن تكون 4 أحرف على الأقل';
                return null;
              },
            ),
            const SizedBox(height: 14),
            _fieldRow(
              controller: _confirmCtrl,
              label: 'تأكيد كلمة المرور الجديدة',
              icon: Icons.lock_rounded,
              obscure: _obscureConf,
              onToggle: () => setState(() => _obscureConf = !_obscureConf),
              validator: (v) {
                if (v != _newPassCtrl.text) return 'كلمتا المرور غير متطابقتين';
                return null;
              },
            ),

            // ── خطأ ──
            if (_error != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.loss.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.loss.withOpacity(0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AppColors.loss, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error!,
                        style: GoogleFonts.cairo(
                            color: AppColors.loss, fontSize: 12)),
                  ),
                ]),
              ),
            ],

            const SizedBox(height: 24),

            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text('إلغاء',
                      style: GoogleFonts.cairo(color: AppColors.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.black54))
                      : Text('تغيير كلمة المرور',
                          style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _fieldRow({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.cairo(color: AppColors.textPrimary, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textHint),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded,
            size: 18, color: AppColors.textHint,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
