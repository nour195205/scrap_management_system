import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/capital_security_service.dart';
import '../../app_theme.dart';

/// حوار إدخال الباسوورد للدخول على الخزنة
/// يرجع true لو الدخول صح
Future<bool> showCapitalLockDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _CapitalLockDialog(),
      ) ??
      false;
}

class _CapitalLockDialog extends StatefulWidget {
  const _CapitalLockDialog();
  @override
  State<_CapitalLockDialog> createState() => _CapitalLockDialogState();
}

class _CapitalLockDialogState extends State<_CapitalLockDialog>
    with SingleTickerProviderStateMixin {
  final _passCtrl   = TextEditingController();
  final _answerCtrl = TextEditingController();

  bool _obscurePass   = true;
  bool _obscureAnswer = true;
  bool _loading       = false;
  bool _showRecovery  = false;
  String? _error;
  String? _securityQuestion;
  int  _failCount = 0;

  late AnimationController _shakeCtrl;
  late Animation<double>   _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _shakeAnim = Tween<double>(begin: 0, end: 1)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeCtrl);
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    final q = await CapitalSecurityService().getSecurityQuestion();
    setState(() => _securityQuestion = q);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _passCtrl.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _tryEnter() async {
    setState(() { _error = null; _loading = true; });
    final ok = await CapitalSecurityService().verifyPassword(_passCtrl.text);
    setState(() => _loading = false);
    if (ok) {
      if (mounted) Navigator.of(context).pop(true);
    } else {
      _failCount++;
      _shakeCtrl.forward(from: 0);
      setState(() {
        _error = _failCount >= 3
            ? 'كلمة مرور خاطئة (${_failCount} محاولات). يمكنك استخدام سؤال الأمان'
            : 'كلمة مرور خاطئة';
      });
    }
  }

  Future<void> _tryRecovery() async {
    setState(() { _error = null; _loading = true; });
    final ok =
        await CapitalSecurityService().verifySecurityAnswer(_answerCtrl.text);
    setState(() => _loading = false);
    if (ok) {
      if (mounted) Navigator.of(context).pop(true);
    } else {
      _shakeCtrl.forward(from: 0);
      setState(() => _error = 'إجابة خاطئة، حاول مرة أخرى');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (_, child) {
        final offset = _shakeCtrl.isAnimating
            ? Offset(8 * (0.5 - _shakeAnim.value), 0)
            : Offset.zero;
        return Transform.translate(offset: offset, child: child);
      },
      child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 420,
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gold.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // أيقونة القفل
              Container(
                width: 70, height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A1200), Color(0xFF2C2000)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold.withOpacity(0.5), width: 2),
                ),
                child: const Icon(Icons.lock_rounded,
                    color: AppColors.gold, size: 32),
              ),
              const SizedBox(height: 18),
              Text('الخزنة محمية',
                  style: GoogleFonts.cairo(
                      fontSize: 20, fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(
                _showRecovery
                    ? 'أجب على سؤال الأمان للدخول'
                    : 'أدخل كلمة المرور للوصول إلى الخزنة',
                style: GoogleFonts.cairo(
                    fontSize: 13, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              if (!_showRecovery) ...[
                // ── إدخال الباسوورد ──
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  autofocus: true,
                  onFieldSubmitted: (_) => _tryEnter(),
                  style:
                      GoogleFonts.cairo(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'كلمة المرور',
                    hintText: '••••••••',
                    prefixIcon: const Icon(Icons.lock_outline_rounded,
                        size: 18, color: AppColors.textHint),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        size: 18, color: AppColors.textHint,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () =>
                        setState(() { _showRecovery = true; _error = null; }),
                    child: Text('نسيت كلمة المرور؟',
                        style: GoogleFonts.cairo(
                            fontSize: 12, color: AppColors.primary)),
                  ),
                ),
              ] else ...[
                // ── استعادة بالسؤال ──
                if (_securityQuestion != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.25)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.help_outline_rounded,
                          color: AppColors.primary, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_securityQuestion!,
                            style: GoogleFonts.cairo(
                                fontSize: 13, color: AppColors.textPrimary)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 14),
                ],
                TextFormField(
                  controller: _answerCtrl,
                  obscureText: _obscureAnswer,
                  autofocus: true,
                  onFieldSubmitted: (_) => _tryRecovery(),
                  style:
                      GoogleFonts.cairo(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'إجابة سؤال الأمان',
                    hintText: 'اكتب إجابتك',
                    prefixIcon: const Icon(Icons.help_outline_rounded,
                        size: 18, color: AppColors.textHint),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureAnswer
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        size: 18, color: AppColors.textHint,
                      ),
                      onPressed: () =>
                          setState(() => _obscureAnswer = !_obscureAnswer),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: () =>
                        setState(() { _showRecovery = false; _error = null; }),
                    child: Text('رجوع لكلمة المرور',
                        style: GoogleFonts.cairo(
                            fontSize: 12, color: AppColors.primary)),
                  ),
                ),
              ],

              // ── رسالة الخطأ ──
              if (_error != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.loss.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppColors.loss.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.loss, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: GoogleFonts.cairo(
                              color: AppColors.loss, fontSize: 12)),
                    ),
                  ]),
                ),
              ],

              const SizedBox(height: 22),

              // ── أزرار ──
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
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
                    onPressed: _loading
                        ? null
                        : (_showRecovery ? _tryRecovery : _tryEnter),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.black54))
                        : Text(_showRecovery ? 'تأكيد الإجابة' : 'دخول الخزنة',
                            style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold)),
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
