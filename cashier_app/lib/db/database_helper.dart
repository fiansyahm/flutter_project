import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'adapters.dart'; // Import Product, PurchaseTransaction, Category, StoreProfile, Cashier, and StockTransaction adapters

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static late Box<Product> _productBox;
  static late Box<PurchaseTransaction> _transactionBox;
  static late Box<Category> _categoryBox;
  static late Box<StoreProfile> _storeProfileBox;
  static late Box<Cashier> _cashierBox;
  static late Box<StockTransaction> _stockTransactionBox; // Added for StockTransaction

  DatabaseHelper._init();

  Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(ProductAdapter());
    Hive.registerAdapter(PurchaseTransactionAdapter());
    Hive.registerAdapter(CategoryAdapter());
    Hive.registerAdapter(StoreProfileAdapter());
    Hive.registerAdapter(CashierAdapter());
    Hive.registerAdapter(StockTransactionAdapter()); // Added for StockTransaction

    // Open all boxes
    _productBox = await Hive.openBox<Product>('productsBox');
    _transactionBox = await Hive.openBox<PurchaseTransaction>('transactionsBox');
    _categoryBox = await Hive.openBox<Category>('categoriesBox');
    _storeProfileBox = await Hive.openBox<StoreProfile>('storeProfileBox');
    _cashierBox = await Hive.openBox<Cashier>('cashiersBox');
    _stockTransactionBox = await Hive.openBox<StockTransaction>('stockTransactionsBox'); // Added for StockTransaction

    // Initialize with a default cashier if the box is empty
    if (_cashierBox.isEmpty) {
      await _cashierBox.add(Cashier(name: 'Kasir 1'));
    }
  }

  // Product Methods
  Future<int> insertProduct(Product product) async {
    final key = await _productBox.add(product);
    product.id = key;
    await _productBox.put(key, product);
    return key;
  }

  Future<List<Product>> getProducts() async {
    return _productBox.values.toList();
  }

  Future<void> updateProduct(Product product) async {
    if (product.id != null) {
      await _productBox.put(product.id!, product);
    }
  }

  Future<void> deleteProduct(int id) async {
    await _productBox.delete(id);
  }

  Future<void> updateStock(int id, int newStock) async {
    final product = _productBox.get(id);
    if (product != null) {
      product.stock = newStock;
      await _productBox.put(id, product);
    }
  }

  // Transaction Methods
  Future<int> insertTransaction(PurchaseTransaction transaction) async {
    final key = await _transactionBox.add(transaction);
    transaction.id = key;
    await _transactionBox.put(key, transaction);
    return key;
  }

  Future<List<PurchaseTransaction>> getTransactions() async {
    return _transactionBox.values.toList();
  }

  // Category Methods
  Future<int> insertCategory(Category category) async {
    final key = await _categoryBox.add(category);
    category.id = key;
    await _categoryBox.put(key, category);
    return key;
  }

  Future<List<Category>> getCategories() async {
    return _categoryBox.values.toList();
  }

  Future<void> updateCategory(Category category) async {
    if (category.id != null) {
      await _categoryBox.put(category.id!, category);
    }
  }

  Future<void> deleteCategory(int id) async {
    final category = _categoryBox.get(id);
    if (category != null) {
      final productsUsingCategory = _productBox.values.where((product) => product.category == category.name).toList();
      if (productsUsingCategory.isNotEmpty) {
        throw Exception('Cannot delete category "${category.name}" because it is used by ${productsUsingCategory.length} product(s).');
      }
      await _categoryBox.delete(id);
    }
  }

  // Store Profile Methods
  Future<StoreProfile?> getStoreProfile() async {
    if (!_storeProfileBox.isOpen) {
      await Hive.openBox<Map<String, dynamic>>('storeProfileBox');
    }
    final data = _storeProfileBox.get('storeProfile');
    return data;
  }

  Future<void> saveStoreProfile(StoreProfile profile) async {
    if (!_storeProfileBox.isOpen) {
      await Hive.openBox<Map<String, dynamic>>('storeProfileBox');
    }
    await _storeProfileBox.put('storeProfile', profile);
  }

  // Cashier Methods
  Future<int> insertCashier(Cashier cashier) async {
    final key = await _cashierBox.add(cashier);
    cashier.id = key;
    await _cashierBox.put(key, cashier);
    return key;
  }

  Future<List<Cashier>> getCashiers() async {
    return _cashierBox.values.toList();
  }

  Future<void> updateCashier(Cashier cashier) async {
    if (cashier.id != null) {
      await _cashierBox.put(cashier.id!, cashier);
    }
  }

  Future<void> deleteCashier(int id) async {
    await _cashierBox.delete(id);
  }

  // Stock Transaction Methods
  Future<int> insertStockTransaction(StockTransaction transaction) async {
    final key = await _stockTransactionBox.add(transaction);
    transaction.id = key;
    await _stockTransactionBox.put(key, transaction);
    return key;
  }

  Future<List<StockTransaction>> getStockTransactions() async {
    return _stockTransactionBox.values.toList();
  }

  Future<void> close() async {
    await _productBox.close();
    await _transactionBox.close();
    await _categoryBox.close();
    await _storeProfileBox.close();
    await _cashierBox.close();
    await _stockTransactionBox.close(); // Added for StockTransaction
    await Hive.close();
  }

  Future<void> resetDatabase() async {
    await _productBox.clear();
    await _transactionBox.clear();
    await _categoryBox.clear();
    await _storeProfileBox.clear();
    await _cashierBox.clear();
    await _stockTransactionBox.clear();
    if (_cashierBox.isEmpty) {
      await _cashierBox.add(Cashier(name: 'Kasir 1'));
    }
  }
}