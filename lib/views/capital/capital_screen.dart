import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../app_theme.dart';
import '../../services/app_state.dart';

class CapitalScreen extends StatefulWidget {
  const CapitalScreen({super.key});
  @override
  State<CapitalScreen> createState() => _CapitalScreenState();
}

class _CapitalScreenState extends State<CapitalScreen> {
  final _setCtrl  = TextEditingController();
  final _addCtrl  = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isAdding  = true; // true = add, false = subtract

  @override
  void dispose() {
    _setCtrl.dispose(); _addCtrl.dispose(); _noteCtrl.dispose();
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
                        color: AppColors.gold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded,
                          color: AppColors.gold, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('إدارة الخزنة',
                            style: GoogleFonts.cairo(
                                fontSize: 26, fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary)),
                        Text('تتبع رأس المال والسيولة',
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
                    // Balance display
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          _buildBalanceCard(state, fmt),
                          const SizedBox(height: 16),
                          _buildSetCapital(state, fmt),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Adjust capital
                    Expanded(
                      flex: 2,
                      child: _buildAdjustCard(state, fmt),
                    ),
                    const SizedBox(width: 20),
                    // Stats column
                    Expanded(
                      flex: 3,
                      child: _buildCapitalStats(state, fmt),
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

  Widget _buildBalanceCard(AppState state, NumberFormat fmt) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1D2E), Color(0xFF252840)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded,
                  color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              Text('رصيد الخزنة',
                  style: GoogleFonts.cairo(
                      fontSize: 14, color: AppColors.gold)),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${fmt.format(state.capitalBalance)} ج',
            style: GoogleFonts.cairo(
                fontSize: 36, fontWeight: FontWeight.bold,
                color: state.capitalBalance >= 0 ? AppColors.gold : AppColors.loss),
          ),
          const SizedBox(height: 8),
          Text(
            state.capitalBalance >= 0 ? 'الخزنة في حالة جيدة' : '⚠ الخزنة في العجز',
            style: GoogleFonts.cairo(
                fontSize: 13,
                color: state.capitalBalance >= 0 ? AppColors.profit : AppColors.loss),
          ),
        ],
      ),
    );
  }

  Widget _buildSetCapital(AppState state, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تعيين رأس المال',
              style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('تغيير قيمة الخزنة مباشرة',
              style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _setCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            style: GoogleFonts.cairo(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'المبلغ الجديد',
              hintText: '0.00',
              prefixIcon: Icon(Icons.edit_rounded, size: 18, color: AppColors.textHint),
              suffixText: 'جنيه',
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final v = double.tryParse(_setCtrl.text);
                if (v == null) return;
                await state.setCapital(v);
                _setCtrl.clear();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('✅ تم تحديث رأس المال', style: GoogleFonts.cairo()),
                  backgroundColor: AppColors.profit,
                ));
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
              child: Text('تحديث الخزنة',
                  style: GoogleFonts.cairo(
                      fontWeight: FontWeight.bold, color: Colors.black87)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustCard(AppState state, NumberFormat fmt) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('تعديل الخزنة',
              style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 4),
          Text('إضافة أو خصم مبلغ من الخزنة',
              style: GoogleFonts.cairo(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),

          // Add / Subtract toggle
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(child: GestureDetector(
                  onTap: () => setState(() => _isAdding = true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _isAdding ? AppColors.profit : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text('إيداع +',
                          style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold, fontSize: 14,
                              color: _isAdding ? Colors.white : AppColors.textSecondary)),
                    ),
                  ),
                )),
                Expanded(child: GestureDetector(
                  onTap: () => setState(() => _isAdding = false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: !_isAdding ? AppColors.loss : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text('سحب -',
                          style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold, fontSize: 14,
                              color: !_isAdding ? Colors.white : AppColors.textSecondary)),
                    ),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _addCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
            style: GoogleFonts.cairo(color: AppColors.textPrimary),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'المبلغ',
              hintText: '0.00',
              prefixIcon: Icon(
                _isAdding ? Icons.add_rounded : Icons.remove_rounded,
                size: 18,
                color: _isAdding ? AppColors.profit : AppColors.loss,
              ),
              suffixText: 'جنيه',
            ),
          ),
          const SizedBox(height: 14),

          // Preview
          if ((double.tryParse(_addCtrl.text) ?? 0) > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('الرصيد الجديد:', style: GoogleFonts.cairo(
                      fontSize: 13, color: AppColors.textSecondary)),
                  Text(
                    '${fmt.format(state.capitalBalance + (double.tryParse(_addCtrl.text) ?? 0) * (_isAdding ? 1 : -1))} ج',
                    style: GoogleFonts.cairo(
                        fontSize: 14, fontWeight: FontWeight.bold,
                        color: _isAdding ? AppColors.profit : AppColors.loss),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final v = double.tryParse(_addCtrl.text);
                if (v == null || v <= 0) return;
                await state.adjustCapital(_isAdding ? v : -v);
                _addCtrl.clear();
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                    '✅ تم ${_isAdding ? "إضافة" : "خصم"} ${fmt.format(v)} جنيه',
                    style: GoogleFonts.cairo(),
                  ),
                  backgroundColor: AppColors.profit,
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _isAdding ? AppColors.profit : AppColors.loss,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(_isAdding ? 'إيداع في الخزنة' : 'سحب من الخزنة',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapitalStats(AppState state, NumberFormat fmt) {
    final allSales     = state.transactions.where((t) => t.isSell).fold(0.0, (s, t) => s + t.totalPrice);
    final allPurchases = state.transactions.where((t) => t.isBuy).fold(0.0, (s, t) => s + t.totalPrice);
    final totalProfit  = state.transactions.where((t) => t.isSell).fold(0.0, (s, t) => s + t.netProfit);
    final stockValue   = state.totalStockValue;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('إحصائيات المالية الكاملة',
              style: GoogleFonts.cairo(fontSize: 15, fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary)),
          const SizedBox(height: 20),
          _statRow(Icons.trending_up_rounded, 'إجمالي المبيعات', '${fmt.format(allSales)} ج', AppColors.profit),
          _statRow(Icons.trending_down_rounded, 'إجمالي المشتريات', '${fmt.format(allPurchases)} ج', AppColors.info),
          _statRow(Icons.monetization_on_rounded, 'صافي الأرباح الكلي', '${fmt.format(totalProfit)} ج',
              totalProfit >= 0 ? AppColors.gold : AppColors.loss),
          const Divider(height: 24),
          _statRow(Icons.inventory_2_rounded, 'قيمة المخزون الحالي', '${fmt.format(stockValue)} ج', AppColors.primary),
          _statRow(Icons.account_balance_rounded, 'رصيد الخزنة', '${fmt.format(state.capitalBalance)} ج', AppColors.gold),
          const SizedBox(height: 4),
          const Divider(height: 24),
          _statRow(Icons.savings_rounded, 'الثروة الكاملة (خزنة + مخزون)',
              '${fmt.format(state.capitalBalance + stockValue)} ج', AppColors.goldLight),
        ],
      ),
    );
  }

  Widget _statRow(IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: GoogleFonts.cairo(
                fontSize: 13, color: AppColors.textSecondary)),
          ),
          Text(value, style: GoogleFonts.cairo(
              fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
