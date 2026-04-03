class Product {
  final int? id;
  final String name;
  final double currentStock; // الكمية المتوفرة
  final double buyPrice;    // سعر الشراء للكيلو
  final double sellPrice;   // سعر البيع للكيلو

  Product({
    this.id,
    required this.name,
    this.currentStock = 0.0,
    required this.buyPrice,
    required this.sellPrice,
  });

  // تحويل البيانات لـ Map عشان تتخزن في SQLite
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'current_stock': currentStock,
      'buy_price': buyPrice,
      'sell_price': sellPrice,
    };
  }
}