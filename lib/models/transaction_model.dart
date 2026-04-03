enum TransactionType { buy, sell }

class ScrapTransaction {
  final int id;
  final int productId;
  final String productName;
  final TransactionType type;
  final double weight;      // دايماً بالكيلو
  final double unitPrice;   // للكيلو
  final double totalPrice;
  final double netProfit;   // للبيع فقط
  final DateTime date;
  final String? notes;

  ScrapTransaction({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.weight,
    required this.unitPrice,
    required this.totalPrice,
    this.netProfit = 0.0,
    DateTime? date,
    this.notes,
  }) : date = date ?? DateTime.now();

  // ---- Derived ----
  double get weightTons => weight / 1000;
  bool   get isBuy  => type == TransactionType.buy;
  bool   get isSell => type == TransactionType.sell;
  String get typeAr => isBuy ? 'شراء' : 'بيع';

  Map<String, dynamic> toMap() => {
    'id': id, 'product_id': productId, 'product_name': productName,
    'type': type.name, 'weight': weight, 'unit_price': unitPrice,
    'total_price': totalPrice, 'net_profit': netProfit,
    'date': date.toIso8601String(), 'notes': notes,
  };

  factory ScrapTransaction.fromMap(Map<String, dynamic> m) => ScrapTransaction(
    id: m['id'], productId: m['product_id'], productName: m['product_name'],
    type: TransactionType.values.firstWhere((e) => e.name == m['type']),
    weight: m['weight'], unitPrice: m['unit_price'],
    totalPrice: m['total_price'], netProfit: m['net_profit'] ?? 0.0,
    date: DateTime.parse(m['date']), notes: m['notes'],
  );
}
