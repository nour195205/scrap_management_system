import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/product_model.dart';
import '../models/transaction_model.dart';
import '../services/capital_security_service.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _db;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dir  = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'qasem_v1.db');

    return await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  Future _onCreate(Database db, int version) async {
    // ── جدول الأصناف ──
    await db.execute('''
      CREATE TABLE products (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        name            TEXT    NOT NULL,
        current_stock   REAL    DEFAULT 0.0,
        buy_price       REAL    DEFAULT 0.0,
        sell_price      REAL    DEFAULT 0.0,
        min_stock_alert REAL    DEFAULT 100.0,
        created_at      TEXT    NOT NULL
      )
    ''');

    // ── جدول العمليات ──
    await db.execute('''
      CREATE TABLE transactions (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id   INTEGER,
        product_name TEXT,
        type         TEXT,
        weight       REAL,
        unit_price   REAL,
        total_price  REAL,
        net_profit   REAL DEFAULT 0.0,
        date         TEXT,
        notes        TEXT,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // ── جدول الخزنة ──
    await db.execute('''
      CREATE TABLE capital (
        id      INTEGER PRIMARY KEY,
        balance REAL DEFAULT 0.0
      )
    ''');
    await db.insert('capital', {'id': 1, 'balance': 0.0});

    // ── جدول أمان الخزنة ──
    await _createSecurityTable(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createSecurityTable(db);
    }
  }

  Future<void> _createSecurityTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS capital_security (
        id               INTEGER PRIMARY KEY,
        password_hash    TEXT NOT NULL,
        security_question TEXT NOT NULL,
        security_answer_hash TEXT NOT NULL
      )
    ''');
  }

  // ════════════════════════════════════
  //  PRODUCTS
  // ════════════════════════════════════
  Future<int> insertProduct(Product p) async {
    final db = await database;
    return await db.insert('products', {
      'name': p.name,
      'current_stock':   p.currentStock,
      'buy_price':       p.buyPrice,
      'sell_price':      p.sellPrice,
      'min_stock_alert': p.minStockAlert,
      'created_at':      p.createdAt.toIso8601String(),
    });
  }

  Future<void> updateProduct(Product p) async {
    final db = await database;
    await db.update('products', {
      'name':            p.name,
      'current_stock':   p.currentStock,
      'buy_price':       p.buyPrice,
      'sell_price':      p.sellPrice,
      'min_stock_alert': p.minStockAlert,
    }, where: 'id = ?', whereArgs: [p.id]);
  }

  Future<void> updateProductStock(int id, double newStock) async {
    final db = await database;
    await db.update('products', {'current_stock': newStock},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteProduct(int id) async {
    final db = await database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Product>> getAllProducts() async {
    final db   = await database;
    final maps = await db.query('products', orderBy: 'created_at ASC');
    return maps.map((m) => Product.fromMap({
      'id':              m['id'],
      'name':            m['name'],
      'current_stock':   m['current_stock'],
      'buy_price':       m['buy_price'],
      'sell_price':      m['sell_price'],
      'min_stock_alert': m['min_stock_alert'],
      'created_at':      m['created_at'],
    })).toList();
  }

  // ════════════════════════════════════
  //  TRANSACTIONS
  // ════════════════════════════════════
  Future<int> insertTransaction(ScrapTransaction t) async {
    final db = await database;
    return await db.insert('transactions', {
      'product_id':   t.productId,
      'product_name': t.productName,
      'type':         t.type.name,
      'weight':       t.weight,
      'unit_price':   t.unitPrice,
      'total_price':  t.totalPrice,
      'net_profit':   t.netProfit,
      'date':         t.date.toIso8601String(),
      'notes':        t.notes,
    });
  }

  Future<List<ScrapTransaction>> getAllTransactions() async {
    final db   = await database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((m) => ScrapTransaction(
      id:          m['id'] as int,
      productId:   m['product_id'] as int,
      productName: m['product_name'] as String,
      type: TransactionType.values.firstWhere((e) => e.name == m['type']),
      weight:     (m['weight'] as num).toDouble(),
      unitPrice:  (m['unit_price'] as num).toDouble(),
      totalPrice: (m['total_price'] as num).toDouble(),
      netProfit:  (m['net_profit'] as num? ?? 0).toDouble(),
      date:       DateTime.parse(m['date'] as String),
      notes:      m['notes'] as String?,
    )).toList();
  }

  Future<void> deleteTransaction(int id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateTransaction(ScrapTransaction t) async {
    final db = await database;
    await db.update('transactions', {
      'product_id':   t.productId,
      'product_name': t.productName,
      'type':         t.type.name,
      'weight':       t.weight,
      'unit_price':   t.unitPrice,
      'total_price':  t.totalPrice,
      'net_profit':   t.netProfit,
      'date':         t.date.toIso8601String(),
      'notes':        t.notes,
    }, where: 'id = ?', whereArgs: [t.id]);
  }

  // ════════════════════════════════════
  //  CAPITAL
  // ════════════════════════════════════
  Future<double> getCapital() async {
    final db     = await database;
    final result = await db.query('capital', where: 'id = 1');
    if (result.isEmpty) return 0.0;
    return (result.first['balance'] as num).toDouble();
  }

  Future<void> updateCapital(double balance) async {
    final db = await database;
    await db.update('capital', {'balance': balance},
        where: 'id = 1', whereArgs: []);
  }

  // ════════════════════════════════════
  //  CAPITAL SECURITY
  // ════════════════════════════════════
  Future<CapitalSecurityData?> getCapitalSecurity() async {
    final db     = await database;
    final result = await db.query('capital_security', where: 'id = 1');
    if (result.isEmpty) return null;
    final row = result.first;
    return CapitalSecurityData(
      passwordHash:       row['password_hash'] as String,
      securityQuestion:   row['security_question'] as String,
      securityAnswerHash: row['security_answer_hash'] as String,
    );
  }

  Future<void> saveCapitalSecurity(CapitalSecurityData data) async {
    final db  = await database;
    final existing = await db.query('capital_security', where: 'id = 1');
    final map = {
      'id': 1,
      'password_hash':       data.passwordHash,
      'security_question':   data.securityQuestion,
      'security_answer_hash': data.securityAnswerHash,
    };
    if (existing.isEmpty) {
      await db.insert('capital_security', map);
    } else {
      await db.update('capital_security', map, where: 'id = 1');
    }
  }
}