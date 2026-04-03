class Product {
  final int id;
  final String name;
  double currentStock;    // الكمية دايماً بالكيلو
  double buyPrice;        // سعر الشراء للكيلو
  double sellPrice;       // سعر البيع للكيلو
  double minStockAlert;   // حد التنبيه بالكيلو
  final DateTime createdAt;

  Product({
    required this.id,
    required this.name,
    this.currentStock  = 0.0,
    required this.buyPrice,
    required this.sellPrice,
    this.minStockAlert = 100.0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // ---- Derived ----
  double get currentStockTons  => currentStock / 1000;
  double get stockValue        => currentStock * buyPrice;
  double get margin            => sellPrice - buyPrice;
  double get marginPercent     => buyPrice > 0 ? (margin / buyPrice) * 100 : 0;
  bool   get isLowStock        => currentStock > 0 && currentStock <= minStockAlert;
  bool   get isOutOfStock      => currentStock <= 0;

  Product copyWith({
    String? name,
    double? currentStock,
    double? buyPrice,
    double? sellPrice,
    double? minStockAlert,
  }) => Product(
    id: id,
    name: name ?? this.name,
    currentStock:   currentStock   ?? this.currentStock,
    buyPrice:       buyPrice       ?? this.buyPrice,
    sellPrice:      sellPrice      ?? this.sellPrice,
    minStockAlert:  minStockAlert  ?? this.minStockAlert,
    createdAt: createdAt,
  );

  Map<String, dynamic> toMap() => {
    'id': id, 'name': name,
    'current_stock': currentStock, 'buy_price': buyPrice,
    'sell_price': sellPrice, 'min_stock_alert': minStockAlert,
    'created_at': createdAt.toIso8601String(),
  };

  factory Product.fromMap(Map<String, dynamic> m) => Product(
    id: m['id'], name: m['name'],
    currentStock:  m['current_stock'],
    buyPrice:      m['buy_price'],
    sellPrice:     m['sell_price'],
    minStockAlert: m['min_stock_alert'] ?? 100.0,
    createdAt:     DateTime.parse(m['created_at']),
  );
}