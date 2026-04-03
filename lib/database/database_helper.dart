import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // تجهيز ffi للعمل على الديسكتوب
    sqfliteFfiInit();
    var databaseFactory = databaseFactoryFfi;

    // تحديد مكان الحفظ (فولدر المستندات للبرنامج)
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, "mizany_database.db");

    return await databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _onCreate,
      ),
    );
  }

  // إنشاء الجداول لأول مرة
  Future _onCreate(Database db, int version) async {
    // 1. جدول المنتجات (المخزون)
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        current_stock REAL DEFAULT 0.0,
        buy_price REAL DEFAULT 0.0,
        sell_price REAL DEFAULT 0.0
      )
    ''');

    // 2. جدول العمليات (بيع وشراء)
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER,
        type TEXT, -- 'BUY' or 'SELL'
        weight REAL,
        unit_price REAL,
        total_price REAL,
        date TEXT,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    // 3. جدول رأس المال (الخزنة)
    await db.execute('''
      CREATE TABLE capital (
        id INTEGER PRIMARY KEY,
        balance REAL DEFAULT 0.0
      )
    ''');
    
    // وضع مبلغ مبدئي في الخزنة (مثلاً 0)
    await db.insert('capital', {'id': 1, 'balance': 0.0});
  }
}