import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../database/database_helper.dart';

class AppState extends ChangeNotifier {
  final _db = DatabaseHelper();

  // ═══════════════════════════════════════════
  //  IN-MEMORY DATA
  // ═══════════════════════════════════════════
  final List<Product> _products = [];
  final List<ScrapTransaction> _transactions = [];
  double _capitalBalance = 0.0;
  int _navIndex = 0;
  int _nextPid  = 1;
  int _nextTid  = 1;
  bool _isLoading = true;

  // ═══════════════════════════════════════════
  //  DATABASE INIT
  // ═══════════════════════════════════════════
  Future<void> initFromDatabase() async {
    final products     = await _db.getAllProducts();
    final transactions = await _db.getAllTransactions();
    final capital      = await _db.getCapital();

    _products.addAll(products);
    _transactions.addAll(transactions);
    _capitalBalance = capital;

    // تحديد الـ IDs الأعلى لتجنب التكرار
    if (products.isNotEmpty) {
      _nextPid = products.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;
    }
    if (transactions.isNotEmpty) {
      _nextTid = transactions.map((t) => t.id).reduce((a, b) => a > b ? a : b) + 1;
    }

    _isLoading = false;
    notifyListeners();
  }

  // ═══════════════════════════════════════════
  //  NAVIGATION
  // ═══════════════════════════════════════════
  int  get navIndex  => _navIndex;
  bool get isLoading => _isLoading;
  void navigateTo(int index) { _navIndex = index; notifyListeners(); }

  // ═══════════════════════════════════════════
  //  GETTERS
  // ═══════════════════════════════════════════
  List<Product>          get products     => List.unmodifiable(_products);
  List<ScrapTransaction> get transactions => List.unmodifiable(_transactions);
  double get capitalBalance    => _capitalBalance;

  List<Product> get lowStockProducts   => _products.where((p) => p.isLowStock).toList();
  List<Product> get outOfStockProducts => _products.where((p) => p.isOutOfStock).toList();
  double get totalStockValue           => _products.fold(0, (s, p) => s + p.stockValue);

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
  Future<void> addProduct({
    required String name,
    required double buyPrice,
    required double sellPrice,
    double currentStock  = 0.0,
    double minStockAlert = 100.0,
  }) async {
    final tempProduct = Product(
      id: 0, name: name, buyPrice: buyPrice, sellPrice: sellPrice,
      currentStock: currentStock, minStockAlert: minStockAlert,
    );
    final insertedId = await _db.insertProduct(tempProduct);
    _products.add(Product(
      id: insertedId, name: name, buyPrice: buyPrice, sellPrice: sellPrice,
      currentStock: currentStock, minStockAlert: minStockAlert,
    ));
    _nextPid = insertedId + 1;
    notifyListeners();
  }

  Future<void> updateProduct(Product updated) async {
    await _db.updateProduct(updated);
    final i = _products.indexWhere((p) => p.id == updated.id);
    if (i != -1) { _products[i] = updated; notifyListeners(); }
  }

  /// Returns false if product has transactions
  Future<bool> deleteProduct(int id) async {
    if (_transactions.any((t) => t.productId == id)) return false;
    await _db.deleteProduct(id);
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
  Future<String?> registerBuy({
    required int productId,
    required double weightKg,
    required double unitPricePerKg,
    String? notes,
  }) async {
    final product = getProduct(productId);
    if (product == null) return 'الصنف غير موجود';
    if (weightKg <= 0) return 'الوزن يجب أن يكون أكبر من صفر';
    if (unitPricePerKg <= 0) return 'السعر يجب أن يكون أكبر من صفر';

    final total = weightKg * unitPricePerKg;

    // تحديث الخزنة
    _capitalBalance -= total;
    await _db.updateCapital(_capitalBalance);

    // حساب متوسط سعر الشراء الجديد (Moving Average Cost)
    final newStock = product.currentStock + weightKg;
    if (newStock > 0) {
      product.buyPrice = ((product.currentStock * product.buyPrice) + total) / newStock;
    }
    product.currentStock = newStock;
    await _db.updateProduct(product);

    // تسجيل العملية
    final tx = ScrapTransaction(
      id: 0, productId: productId, productName: product.name,
      type: TransactionType.buy, weight: weightKg,
      unitPrice: unitPricePerKg, totalPrice: total, netProfit: 0, notes: notes,
    );
    final insertedId = await _db.insertTransaction(tx);
    _transactions.add(ScrapTransaction(
      id: insertedId, productId: productId, productName: product.name,
      type: TransactionType.buy, weight: weightKg,
      unitPrice: unitPricePerKg, totalPrice: total, netProfit: 0, notes: notes,
    ));

    notifyListeners();
    return null;
  }

  Future<String?> registerSell({
    required int productId,
    required double weightKg,
    required double unitPricePerKg,
    String? notes,
  }) async {
    final product = getProduct(productId);
    if (product == null) return 'الصنف غير موجود';
    if (weightKg <= 0) return 'الوزن يجب أن يكون أكبر من صفر';
    if (unitPricePerKg <= 0) return 'السعر يجب أن يكون أكبر من صفر';
    if (product.currentStock < weightKg) {
      return 'المخزون غير كافي (المتاح: ${product.currentStock.toStringAsFixed(1)} كجم)';
    }

    final total  = weightKg * unitPricePerKg;
    final profit = (unitPricePerKg - product.buyPrice) * weightKg;

    // تحديث الخزنة
    _capitalBalance += total;
    await _db.updateCapital(_capitalBalance);

    // تحديث المخزون
    product.currentStock -= weightKg;
    await _db.updateProductStock(productId, product.currentStock);

    // تسجيل العملية
    final tx = ScrapTransaction(
      id: 0, productId: productId, productName: product.name,
      type: TransactionType.sell, weight: weightKg,
      unitPrice: unitPricePerKg, totalPrice: total, netProfit: profit, notes: notes,
    );
    final insertedId = await _db.insertTransaction(tx);
    _transactions.add(ScrapTransaction(
      id: insertedId, productId: productId, productName: product.name,
      type: TransactionType.sell, weight: weightKg,
      unitPrice: unitPricePerKg, totalPrice: total, netProfit: profit, notes: notes,
    ));

    notifyListeners();
    return null;
  }

  // ═══════════════════════════════════════════
  //  DELETE / UPDATE TRANSACTION
  // ═══════════════════════════════════════════

  /// حذف عملية وعكس تأثيرها على المخزون والخزنة
  Future<String?> deleteTransaction(int transactionId) async {
    final tx = _transactions.firstWhere(
      (t) => t.id == transactionId,
      orElse: () => throw StateError('not found'),
    );

    final product = getProduct(tx.productId);

    if (tx.isBuy) {
      // عكس الشراء: إرجاع الفلوس للخزنة وخصم المخزون
      if (product != null) {
        final newStock = product.currentStock - tx.weight;
        if (newStock < 0) return 'لا يمكن الحذف: المخزون الحالي أقل من وزن العملية';
        
        // تعديل السعر ليعكس الحذف
        if (newStock > 0) {
          final oldTotalValue = (product.currentStock * product.buyPrice) - tx.totalPrice;
          product.buyPrice = oldTotalValue > 0 ? (oldTotalValue / newStock) : product.buyPrice;
        }
        
        product.currentStock = newStock;
        await _db.updateProduct(product);
      }
      _capitalBalance += tx.totalPrice;
    } else {
      // عكس البيع: خصم الفلوس من الخزنة وإرجاع المخزون
      if (product != null) {
        product.currentStock += tx.weight;
        await _db.updateProductStock(tx.productId, product.currentStock);
      }
      _capitalBalance -= tx.totalPrice;
    }

    await _db.updateCapital(_capitalBalance);
    await _db.deleteTransaction(transactionId);
    _transactions.removeWhere((t) => t.id == transactionId);
    notifyListeners();
    return null;
  }

  /// تعديل عملية: عكس القديمة ثم تطبيق الجديدة
  Future<String?> updateTransaction({
    required int transactionId,
    required double newWeightKg,
    required double newUnitPrice,
    String? newNotes,
  }) async {
    final oldTx = _transactions.firstWhere(
      (t) => t.id == transactionId,
      orElse: () => throw StateError('not found'),
    );
    if (newWeightKg <= 0) return 'الوزن يجب أن يكون أكبر من صفر';
    if (newUnitPrice <= 0) return 'السعر يجب أن يكون أكبر من صفر';

    final product = getProduct(oldTx.productId);
    final weightDiff  = newWeightKg - oldTx.weight;
    final newTotal    = newWeightKg * newUnitPrice;
    final totalDiff   = newTotal - oldTx.totalPrice;

    if (oldTx.isBuy) {
      // تعديل شراء: فرق المخزون وفرق الخزنة
      if (product != null) {
        final newStock = product.currentStock + weightDiff;
        if (newStock < 0) return 'لا يمكن التعديل: المخزون سيصبح سالبًا';
        
        // تعديل متوسط السعر
        if (newStock > 0) {
          final valueBeforeOldTx = (product.currentStock * product.buyPrice) - oldTx.totalPrice;
          final newValue = valueBeforeOldTx + newTotal;
          product.buyPrice = newValue > 0 ? (newValue / newStock) : product.buyPrice;
        }
        
        product.currentStock = newStock;
        await _db.updateProduct(product);
      }
      _capitalBalance -= totalDiff;
    } else {
      // تعديل بيع: عكس فرق المخزون وفرق الخزنة
      if (product != null) {
        final newStock = product.currentStock - weightDiff;
        if (newStock < 0) return 'لا يمكن التعديل: المخزون سيصبح سالبًا';
        product.currentStock = newStock;
        await _db.updateProductStock(oldTx.productId, newStock);
      }
      _capitalBalance += totalDiff;
    }

    await _db.updateCapital(_capitalBalance);

    double newProfit = oldTx.netProfit;
    if (oldTx.isSell && product != null) {
      newProfit = (newUnitPrice - product.buyPrice) * newWeightKg;
    }

    final updatedTx = ScrapTransaction(
      id: oldTx.id,
      productId: oldTx.productId,
      productName: oldTx.productName,
      type: oldTx.type,
      weight: newWeightKg,
      unitPrice: newUnitPrice,
      totalPrice: newTotal,
      netProfit: newProfit,
      date: oldTx.date,
      notes: newNotes,
    );

    await _db.updateTransaction(updatedTx);
    final idx = _transactions.indexWhere((t) => t.id == transactionId);
    if (idx != -1) _transactions[idx] = updatedTx;
    notifyListeners();
    return null;
  }

  // ═══════════════════════════════════════════
  //  CAPITAL OPERATIONS
  // ═══════════════════════════════════════════
  Future<void> setCapital(double amount) async {
    _capitalBalance = amount;
    await _db.updateCapital(amount);
    notifyListeners();
  }

  Future<void> adjustCapital(double delta) async {
    _capitalBalance += delta;
    await _db.updateCapital(_capitalBalance);
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
    final list      = getTransactions(from: from, to: to);
    final sales     = list.where((t) => t.isSell);
    final purchases = list.where((t) => t.isBuy);

    final totalSales     = sales.fold(0.0, (s, t) => s + t.totalPrice);
    final totalPurchases = purchases.fold(0.0, (s, t) => s + t.totalPrice);
    final netProfit      = sales.fold(0.0, (s, t) => s + t.netProfit);

    final Map<String, Map<String, dynamic>> perProduct = {};
    for (final t in list) {
      perProduct.putIfAbsent(t.productName, () => {
        'sales': 0.0, 'purchases': 0.0, 'profit': 0.0,
        'sellCount': 0, 'buyCount': 0,
      });
      final p = perProduct[t.productName]!;
      if (t.isSell) {
        p['sales']     = (p['sales'] as double) + t.totalPrice;
        p['profit']    = (p['profit'] as double) + t.netProfit;
        p['sellCount'] = (p['sellCount'] as int) + 1;
      } else {
        p['purchases'] = (p['purchases'] as double) + t.totalPrice;
        p['buyCount']  = (p['buyCount'] as int) + 1;
      }
    }

    return {
      'transactions':    list,
      'totalSales':      totalSales,
      'totalPurchases':  totalPurchases,
      'netProfit':       netProfit,
      'sellCount':       sales.length,
      'buyCount':        purchases.length,
      'perProduct':      perProduct,
    };
  }

  // ═══════════════════════════════════════════
  //  SAMPLE DATA (للاختبار الأولي فقط)
  // ═══════════════════════════════════════════
  Future<void> loadSampleData() async {
    // لا تشغّل لو في بيانات فعلية موجودة
    if (_products.isNotEmpty) return;

    await addProduct(name: 'حديد',     buyPrice: 4.5,  sellPrice: 5.2,  currentStock: 3500, minStockAlert: 500);
    await addProduct(name: 'نحاس',     buyPrice: 50.0, sellPrice: 60.0, currentStock: 180,  minStockAlert: 50);
    await addProduct(name: 'كرتون',    buyPrice: 0.9,  sellPrice: 1.2,  currentStock: 80,   minStockAlert: 200);
    await addProduct(name: 'بلاستيك',  buyPrice: 1.6,  sellPrice: 2.1,  currentStock: 750,  minStockAlert: 150);
    await addProduct(name: 'ألومنيوم', buyPrice: 20.0, sellPrice: 25.0, currentStock: 420,  minStockAlert: 100);

    await setCapital(75000.0);
  }
}
