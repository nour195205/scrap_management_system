import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../app_theme.dart';

// فئات العملة المصرية: القيمة + الاسم + اللون
class _Denomination {
  final double value;
  final String label;
  final Color color;
  final bool isCoin; // عملة معدنية؟
  _Denomination(this.value, this.label, this.color, {this.isCoin = false});
}

final _denominations = [
  _Denomination(200,  '٢٠٠ جنيه',  const Color(0xFF1976D2)),
  _Denomination(100,  '١٠٠ جنيه',  const Color(0xFF388E3C)),
  _Denomination(50,   '٥٠ جنيه',   const Color(0xFF7B1FA2)),
  _Denomination(20,   '٢٠ جنيه',   const Color(0xFFE64A19)),
  _Denomination(10,   '١٠ جنيه',   const Color(0xFF00838F)),
  _Denomination(5,    '٥ جنيه',    const Color(0xFFF57F17)),
  _Denomination(1,    '١ جنيه',    const Color(0xFF546E7A),  isCoin: true),
  _Denomination(0.50, '٥٠ قرش',    const Color(0xFF78909C),  isCoin: true),
  _Denomination(0.25, '٢٥ قرش',    const Color(0xFF90A4AE),  isCoin: true),
];

class CurrencyCounterScreen extends StatefulWidget {
  const CurrencyCounterScreen({super.key});

  @override
  State<CurrencyCounterScreen> createState() => _CurrencyCounterScreenState();
}

class _CurrencyCounterScreenState extends State<CurrencyCounterScreen> {
  // عدد الأوراق/عملات لكل فئة
  final Map<double, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (final d in _denominations) {
      _controllers[d.value] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) c.dispose();
    super.dispose();
  }

  // حساب الإجمالي
  double get _total {
    double sum = 0;
    for (final d in _denominations) {
      final qty = int.tryParse(_controllers[d.value]!.text) ?? 0;
      sum += qty * d.value;
    }
    return sum;
  }

  // تفاصيل كل فئة
  List<Map<String, dynamic>> get _details {
    return _denominations.map((d) {
      final qty = int.tryParse(_controllers[d.value]!.text) ?? 0;
      return {
        'denomination': d,
        'qty': qty,
        'subtotal': qty * d.value,
      };
    }).where((e) => (e['qty'] as int) > 0).toList();
  }

  void _reset() {
    setState(() {
      for (final c in _controllers.values) c.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt    = NumberFormat('#,##0.##');
    final total  = _total;
    final details = _details;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Right: input grid ──────────────────────────
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.payments_rounded,
                            color: AppColors.gold, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('عداد العملة',
                              style: GoogleFonts.cairo(
                                  fontSize: 26,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                          Text('أدخل عدد الأوراق والعملات من كل فئة',
                              style: GoogleFonts.cairo(
                                  fontSize: 13,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: _reset,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: AppColors.loss.withOpacity(0.5)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        icon: Icon(Icons.refresh_rounded,
                            size: 16, color: AppColors.loss),
                        label: Text('مسح الكل',
                            style: GoogleFonts.cairo(
                                color: AppColors.loss, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Section: أوراق ─────────────────────────
                  _sectionLabel('🏦  أوراق نقدية'),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                        // أوراق
                        ..._denominations
                            .where((d) => !d.isCoin)
                            .map((d) => _DenomRow(
                                  denomination: d,
                                  controller: _controllers[d.value]!,
                                  fmt: fmt,
                                  onChanged: () => setState(() {}),
                                )),
                        const SizedBox(height: 16),
                        _sectionLabel('🪙  عملات معدنية'),
                        const SizedBox(height: 12),
                        // عملات
                        ..._denominations
                            .where((d) => d.isCoin)
                            .map((d) => _DenomRow(
                                  denomination: d,
                                  controller: _controllers[d.value]!,
                                  fmt: fmt,
                                  onChanged: () => setState(() {}),
                                )),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 24),

            // ── Left: summary panel ────────────────────────
            SizedBox(
              width: 300,
              child: Column(
                children: [
                  // Total card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.gold.withOpacity(0.25),
                          AppColors.gold.withOpacity(0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.gold.withOpacity(0.4)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet_rounded,
                            color: AppColors.gold, size: 32),
                        const SizedBox(height: 12),
                        Text('الإجمالي',
                            style: GoogleFonts.cairo(
                                fontSize: 14,
                                color: AppColors.textSecondary)),
                        const SizedBox(height: 6),
                        Text(
                          '${fmt.format(total)} ج',
                          style: GoogleFonts.cairo(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: AppColors.gold,
                          ),
                        ),
                        if (total > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '= ${_toArabicWords(total)}',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.cairo(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Breakdown card
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('التفاصيل',
                              style: GoogleFonts.cairo(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 12),
                          if (details.isEmpty)
                            Expanded(
                              child: Center(
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.touch_app_rounded,
                                        size: 40,
                                        color: AppColors.textHint),
                                    const SizedBox(height: 8),
                                    Text('ابدأ بإدخال الأعداد',
                                        style: GoogleFonts.cairo(
                                            color: AppColors.textHint,
                                            fontSize: 13)),
                                  ],
                                ),
                              ),
                            )
                          else
                            Expanded(
                              child: ListView.separated(
                                itemCount: details.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 12),
                                itemBuilder: (_, i) {
                                  final item = details[i];
                                  final d = item['denomination']
                                      as _Denomination;
                                  final qty = item['qty'] as int;
                                  final sub =
                                      item['subtotal'] as double;
                                  return Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: d.color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${d.label} × $qty',
                                          style: GoogleFonts.cairo(
                                              fontSize: 13,
                                              color:
                                                  AppColors.textPrimary),
                                        ),
                                      ),
                                      Text(
                                        '${fmt.format(sub)} ج',
                                        style: GoogleFonts.cairo(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: d.color,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),

                          // Total row at bottom
                          if (details.isNotEmpty) ...[
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text('الإجمالي',
                                    style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary)),
                                Text('${fmt.format(total)} ج',
                                    style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: AppColors.gold)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary),
      );

  /// تحويل بسيط للأرقام لكلمات (مئات وآلاف)
  String _toArabicWords(double amount) {
    final int pounds = amount.floor();
    final int piasters = ((amount - pounds) * 100).round();
    final parts = <String>[];
    if (pounds > 0) parts.add('${NumberFormat('#,##0').format(pounds)} جنيه');
    if (piasters > 0) parts.add('$piasters قرش');
    return parts.join(' و ');
  }
}

// ════════════════════════════════════════════════
//  صف فئة واحدة من العملة
// ════════════════════════════════════════════════
class _DenomRow extends StatefulWidget {
  final _Denomination denomination;
  final TextEditingController controller;
  final NumberFormat fmt;
  final VoidCallback onChanged;

  const _DenomRow({
    required this.denomination,
    required this.controller,
    required this.fmt,
    required this.onChanged,
  });

  @override
  State<_DenomRow> createState() => _DenomRowState();
}

class _DenomRowState extends State<_DenomRow> {
  bool _focused = false;

  int get _qty => int.tryParse(widget.controller.text) ?? 0;
  double get _subtotal => _qty * widget.denomination.value;

  @override
  Widget build(BuildContext context) {
    final d       = widget.denomination;
    final haValue = _qty > 0;
    final fmt     = widget.fmt;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: haValue
              ? d.color.withOpacity(0.07)
              : _focused
                  ? AppColors.surface
                  : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: haValue
                ? d.color.withOpacity(0.4)
                : _focused
                    ? d.color.withOpacity(0.3)
                    : AppColors.border,
            width: haValue || _focused ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Color badge + label
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: d.color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  d.isCoin ? '🪙' : '💵',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Label
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.label,
                      style: GoogleFonts.cairo(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: haValue ? d.color : AppColors.textPrimary)),
                  if (haValue)
                    Text(
                      '= ${fmt.format(_subtotal)} ج',
                      style: GoogleFonts.cairo(
                          fontSize: 12, color: d.color),
                    ),
                ],
              ),
            ),

            // Minus button
            _CircleBtn(
              icon: Icons.remove,
              color: d.color,
              onTap: _qty > 0
                  ? () {
                      widget.controller.text = (_qty - 1).toString();
                      widget.onChanged();
                    }
                  : null,
            ),
            const SizedBox(width: 8),

            // Quantity input
            SizedBox(
              width: 70,
              child: Focus(
                onFocusChange: (f) => setState(() => _focused = f),
                child: TextFormField(
                  controller: widget.controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: haValue ? d.color : AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: GoogleFonts.cairo(
                        color: AppColors.textHint, fontSize: 14),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: d.color, width: 1.5),
                    ),
                  ),
                  onChanged: (_) => widget.onChanged(),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Plus button
            _CircleBtn(
              icon: Icons.add,
              color: d.color,
              onTap: () {
                widget.controller.text = (_qty + 1).toString();
                widget.onChanged();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _CircleBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: onTap != null
              ? color.withOpacity(0.12)
              : AppColors.border.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 18,
          color: onTap != null ? color : AppColors.textHint,
        ),
      ),
    );
  }
}
