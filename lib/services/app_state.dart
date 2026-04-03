import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';

class AppState extends ChangeNotifier {
  // ═══════════════════════════════════════════
  //  DATA
  // ═══════════════════════════════════════════
  final List<Product> _products = [];
  final List<ScrapTransaction> _transactions = [];
  double _capitalBalance = 0.0;
  int _navIndex = 0;
  int _nextPid = 1;
  int _nextTid = 1;

  // ═══════════════════════════════════════════
  //  NAVIGATION
  // ═══════════════════════════════════════════
  int get navIndex => _navIndex;
  void navigateTo(int index) { _navIndex = index; notifyListeners(); }

  // ═══════════════════════════════════════════
  //  GETTERS
  // ═══════════════════════════════════════════
  List<Product> get products       => List.unmodifiable(_products);
  List<ScrapTransaction> get transactions => List.unmodifiable(_transactions);
  double get capitalBalance        => _capitalBalance;

  List<Product> get lowStockProducts  => _products.where((p) => p.isLowStock).toList();
  List<Product> get outOfStockProducts => _products.where((p) => p.isOutOfStock).toList();
  double get totalStockValue       => _products.fold(0, (s, p) => s + p.stockValue);

  List<ScrapTransaction> get recentTransactions {
    final sorted = [..._transactions]..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(20).toList();
  }

  List<ScrapTransaction> get todayTransactions {
    final now = DateTime.now();
    return _transactions.where((t) =>
      t.date.year == now.year && t.date.month == now.month && t.date.day == now.day
    ).toList();
  }

  double get todaySales     => todayTransactions.where((t) => t.isSell).fold(0.0, (s, t) => s + t.totalPrice);
  double get todayPurchases => todayTransactions.where((t) => t.isBuy).fold(0.0, (s, t) => s + t.totalPrice);
  double get todayProfit    => todayTransactions.where((t) => t.isSell).fold(0.0, (s, t) => s + t.netProfit);

  // ═══════════════════════════════════════════
  //  PRODUCT OPERATIONS
  // ═══════════════════════════════════════════
  void addProduct({
    required String name,
    required double buyPrice,
    required double sellPrice,
    double currentStock = 0.0,
    double minStockAlert = 100.0,
  }) {
    _products.add(Product(
      id: _nextPid++, name: name,
      buyPrice: buyPrice, sellPrice: sellPrice,
      currentStock: currentStock, minStockAlert: minStockAlert,
    ));
    notifyListeners();
  }

  void updateProduct(Product updated) {
    final i = _products.indexWhere((p) => p.id == updated.id);
    if (i != -1) { _products[i] = updated; notifyListeners(); }
  }

  /// Returns false if product has transactions (can't delete)
  bool deleteProduct(int id) {
    if (_transactions.any((t) => t.productId == id)) return false;
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
    return true;
  }

  Product? getProduct(int id) {
    try { return _products.firstWhere((p) => p.id == id); } catch (_) { return null; }
  }

  // ═══════════════════════════════════════════
  //  TRANSACTION OPERATIONS
  // ═══════════════════════════════════════════
  /// Returns error string or null on success
  String? registerBuy({
    required int productId,
    required double weightKg,
    required double unitPricePerKg,
    String? notes,
  }) {
    final product = getProduct(productId);
    if (product == null) return 'الصنف غير موجود';
    if (weightKg <= 0) return 'الوزن يجب أن يكون أكبر من صفر';
    if (unitPricePerKg <= 0) return 'السعر يجب أن يكون أكبر من صفر';

    final total = weightKg * unitPricePerKg;
    _capitalBalance -= total;
    product.currentStock += weightKg;
    _transactions.add(ScrapTransaction(
      id: _nextTid++, productId: productId, productName: product.name,
      type: TransactionType.buy, weight: weightKg,
      unitPrice: unitPricePerKg, totalPrice: total, netProfit: 0, notes: notes,
    ));
    notifyListeners();
    return null;
  }

  /// Returns error string or null on success
  String? registerSell({
    required int productId,
    required double weightKg,
    required double unitPricePerKg,
    String? notes,
  }) {
    final product = getProduct(productId);
    if (product == null) return 'الصنف غير موجود';
    if (weightKg <= 0) return 'الوزن يجب أن يكون أكبر من صفر';
    if (unitPricePerKg <= 0) return 'السعر يجب أن يكون أكبر من صفر';
    if (product.currentStock < weightKg) {
      return 'المخزون غير كافي (المتاح: ${product.currentStock.toStringAsFixed(1)} كجم)';
    }

    final total = weightKg * unitPricePerKg;
    final profit = (unitPricePerKg - product.buyPrice) * weightKg;
    _capitalBalance += total;
    product.currentStock -= weightKg;
    _transactions.add(ScrapTransaction(
      id: _nextTid++, productId: productId, productName: product.name,
      type: TransactionType.sell, weight: weightKg,
      unitPrice: unitPricePerKg, totalPrice: total, netProfit: profit, notes: notes,
    ));
    notifyListeners();
    return null;
  }

  // ═══════════════════════════════════════════
  //  CAPITAL OPERATIONS
  // ═══════════════════════════════════════════
  void setCapital(double amount) { _capitalBalance = amount; notifyListeners(); }
  void adjustCapital(double delta, {String? reason}) {
    _capitalBalance += delta;
    notifyListeners();
  }

  // ═══════════════════════════════════════════
  //  REPORTS
  // ═══════════════════════════════════════════
  List<ScrapTransaction> getTransactions({DateTime? from, DateTime? to, TransactionType? type}) {
    return _transactions.where((t) {
      if (from != null && t.date.isBefore(from)) return false;
      if (to != null) {
        final endOfDay = DateTime(to.year, to.month, to.day, 23, 59, 59);
        if (t.date.isAfter(endOfDay)) return false;
      }
      if (type != null && t.type != type) return false;
      return true;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  Map<String, dynamic> buildReport({DateTime? from, DateTime? to}) {
    final list = getTransactions(from: from, to: to);
    final sales     = list.where((t) => t.isSell);
    final purchases = list.where((t) => t.isBuy);
    final totalSales     = sales.fold(0.0, (s, t) => s + t.totalPrice);
    final totalPurchases = purchases.fold(0.0, (s, t) => s + t.totalPrice);
    final netProfit      = sales.fold(0.0, (s, t) => s + t.netProfit);

    // Per-product breakdown
    final Map<String, Map<String, dynamic>> perProduct = {};
    for (final t in list) {
      perProduct.putIfAbsent(t.productName, () => {
        'sales': 0.0, 'purchases': 0.0, 'profit': 0.0,
        'sellCount': 0, 'buyCount': 0,
      });
      final p = perProduct[t.productName]!;
      if (t.isSell) { p['sales'] = (p['sales'] as double) + t.totalPrice; p['profit'] = (p['profit'] as double) + t.netProfit; p['sellCount'] = (p['sellCount'] as int) + 1; }
      else          { p['purchases'] = (p['purchases'] as double) + t.totalPrice; p['buyCount'] = (p['buyCount'] as int) + 1; }
    }

    return {
      'transactions': list,
      'totalSales': totalSales,
      'totalPurchases': totalPurchases,
      'netProfit': netProfit,
      'sellCount': sales.length,
      'buyCount': purchases.length,
      'perProduct': perProduct,
    };
  }

  // ═══════════════════════════════════════════
  //  SAMPLE DATA (للاختبار على المتصفح)
  // ═══════════════════════════════════════════
  void loadSampleData() {
    _products.clear(); _transactions.clear();
    _nextPid = 1; _nextTid = 1;

    // أصناف الخردة
    addProduct(name: 'حديد',      buyPrice: 4.5,  sellPrice: 5.2,  currentStock: 3500, minStockAlert: 500);
    addProduct(name: 'نحاس',      buyPrice: 50.0, sellPrice: 60.0, currentStock: 180,  minStockAlert: 50);
    addProduct(name: 'كرتون',     buyPrice: 0.9,  sellPrice: 1.2,  currentStock: 80,   minStockAlert: 200);
    addProduct(name: 'بلاستيك',   buyPrice: 1.6,  sellPrice: 2.1,  currentStock: 750,  minStockAlert: 150);
    addProduct(name: 'ألومنيوم',  buyPrice: 20.0, sellPrice: 25.0, currentStock: 420,  minStockAlert: 100);

    _capitalBalance = 75000.0;

    final now = DateTime.now();
    // عمليات تجريبية في آخر 14 يوم
    final ops = [
      (1, TransactionType.buy,  500.0, 4.5,  6),
      (1, TransactionType.sell, 200.0, 5.2,  5),
      (2, TransactionType.buy,  60.0,  50.0, 5),
      (2, TransactionType.sell, 30.0,  60.0, 4),
      (3, TransactionType.buy,  400.0, 0.9,  4),
      (4, TransactionType.sell, 200.0, 2.1,  3),
      (5, TransactionType.buy,  150.0, 20.0, 3),
      (1, TransactionType.sell, 300.0, 5.2,  2),
      (5, TransactionType.sell, 100.0, 25.0, 1),
      (2, TransactionType.buy,  40.0,  50.0, 1),
      (1, TransactionType.buy,  600.0, 4.5,  0),
      (4, TransactionType.sell, 150.0, 2.1,  0),
    ];

    for (final (pid, type, w, price, days) in ops) {
      final product = getProduct(pid)!;
      final total   = w * price;
      final profit  = type == TransactionType.sell ? (price - product.buyPrice) * w : 0.0;
      _transactions.add(ScrapTransaction(
        id: _nextTid++, productId: pid, productName: product.name,
        type: type, weight: w, unitPrice: price, totalPrice: total, netProfit: profit,
        date: now.subtract(Duration(days: days)),
      ));
    }
    notifyListeners();
  }
}
