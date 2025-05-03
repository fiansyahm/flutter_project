// db/database_helper.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/purchase_transaction.dart'; // Update the import

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cashier.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        stock INTEGER,
        sku TEXT,
        purchasePrice INTEGER,
        sellingPrice INTEGER,
        category TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        items TEXT,
        total INTEGER,
        paymentMethod TEXT,
        cashier TEXT,
        supplier TEXT,
        discount INTEGER,
        tax INTEGER,
        date TEXT
      )
    ''');
  }

  // Product Methods
  Future<int> insertProduct(Product product) async {
    final db = await database;
    return await db.insert('products', product.toMap());
  }

  Future<List<Product>> getProducts() async {
    final db = await database;
    final maps = await db.query('products');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateStock(int id, int newStock) async {
    final db = await database;
    return await db.update(
      'products',
      {'stock': newStock},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Transaction Methods
  Future<int> insertTransaction(PurchaseTransaction transaction) async { // Update the type
    final db = await database;
    return await db.insert('transactions', transaction.toMap());
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  Future<List<PurchaseTransaction>> getTransactions() async {
    final db = await database;
    final maps = await db.query('transactions');
    return maps.map((map) => PurchaseTransaction.fromMap(map)).toList();
  }

}