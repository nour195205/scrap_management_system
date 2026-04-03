import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../app_theme.dart';
import 'home_screen.dart';
import 'products/products_screen.dart';
import 'transactions/buy_screen.dart';
import 'transactions/sell_screen.dart';
import 'transactions/transactions_history_screen.dart';
import 'inventory/inventory_screen.dart';
import 'reports/reports_screen.dart';
import 'capital/capital_screen.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({super.key});

  static const _items = [
    _NavItem(Icons.dashboard_rounded,              'الرئيسية'),
    _NavItem(Icons.shopping_cart_rounded,          'تسجيل شراء'),
    _NavItem(Icons.sell_rounded,                   'تسجيل بيع'),
    _NavItem(Icons.inventory_2_rounded,            'المخزون'),
    _NavItem(Icons.category_rounded,               'الأصناف'),
    _NavItem(Icons.receipt_long_rounded,           'سجل العمليات'),
    _NavItem(Icons.bar_chart_rounded,              'التقارير'),
    _NavItem(Icons.account_balance_wallet_rounded, 'الخزنة'),
  ];

  static const _screens = [
    HomeScreen(),
    BuyScreen(),
    SellScreen(),
    InventoryScreen(),
    ProductsScreen(),
    TransactionsHistoryScreen(),
    ReportsScreen(),
    CapitalScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final alerts = state.lowStockProducts.length + state.outOfStockProducts.length;
        return Scaffold(
          body: Row(
            children: [
              _Sidebar(
                items: _items,
                selectedIndex: state.navIndex,
                onSelect: state.navigateTo,
                alertCount: alerts,
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: child,
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(state.navIndex),
                    child: _screens[state.navIndex],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────
class _Sidebar extends StatefulWidget {
  final List<_NavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final int alertCount;

  const _Sidebar({
    required this.items,
    required this.selectedIndex,
    required this.onSelect,
    this.alertCount = 0,
  });

  @override
  State<_Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<_Sidebar> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOut,
      width: _expanded ? 220 : 68,
      color: AppColors.surface,
      child: Column(
        children: [
          // ── Logo ──
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: _expanded
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    _logo(),
                    if (_expanded) ...[
                      const SizedBox(width: 10),
                      Text('ميزاني',
                          style: GoogleFonts.cairo(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          )),
                    ],
                  ],
                ),
                if (_expanded)
                  IconButton(
                    onPressed: () => setState(() => _expanded = false),
                    icon: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textSecondary, size: 22),
                    tooltip: 'طي القائمة',
                  ),
              ],
            ),
          ),

          if (!_expanded)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: IconButton(
                onPressed: () => setState(() => _expanded = true),
                icon: const Icon(Icons.chevron_left_rounded,
                    color: AppColors.textSecondary, size: 22),
                tooltip: 'توسيع القائمة',
              ),
            ),

          // ── Nav Items ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              itemCount: widget.items.length,
              itemBuilder: (_, i) {
                final item   = widget.items[i];
                final active = widget.selectedIndex == i;
                // إظهار تنبيه على "المخزون" (index 3)
                final showBadge = i == 3 && widget.alertCount > 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Tooltip(
                    message: _expanded ? '' : item.label,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => widget.onSelect(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 46,
                        padding: EdgeInsets.symmetric(
                            horizontal: _expanded ? 14 : 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: active
                              ? AppColors.primary.withOpacity(0.15)
                              : Colors.transparent,
                          border: active
                              ? Border.all(
                                  color: AppColors.primary.withOpacity(0.35))
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment: _expanded
                              ? MainAxisAlignment.start
                              : MainAxisAlignment.center,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(item.icon,
                                    size: 22,
                                    color: active
                                        ? AppColors.primary
                                        : AppColors.textSecondary),
                                if (showBadge)
                                  Positioned(
                                    top: -4, left: -4,
                                    child: Container(
                                      width: 16, height: 16,
                                      decoration: const BoxDecoration(
                                        color: AppColors.warning,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text('${widget.alertCount}',
                                            style: const TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white)),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (_expanded) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(item.label,
                                    style: GoogleFonts.cairo(
                                      color: active
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                      fontWeight: active
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 13.5,
                                    )),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (_expanded)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('الإصدار 1.0.0',
                  style: GoogleFonts.cairo(
                      color: AppColors.textHint, fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _logo() => Container(
        width: 38, height: 38,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.recycling, color: Colors.white, size: 22),
      );
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
