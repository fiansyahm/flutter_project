import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'adapters.dart'; // Import Product, PurchaseTransaction, and Category from adapters.dart

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static late Box<Product> _productBox;
  static late Box<PurchaseTransaction> _transactionBox;
  static late Box<Category> _categoryBox;

  DatabaseHelper._init();

  Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(ProductAdapter());
    Hive.registerAdapter(PurchaseTransactionAdapter());
    Hive.registerAdapter(CategoryAdapter());

    _productBox = await Hive.openBox<Product>('productsBox');
    _transactionBox = await Hive.openBox<PurchaseTransaction>('transactionsBox');
    _categoryBox = await Hive.openBox<Category>('categoriesBox');
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
    // Check if any products are using this category
    final category = _categoryBox.get(id);
    if (category != null) {
      final productsUsingCategory = _productBox.values.where((product) => product.category == category.name).toList();
      if (productsUsingCategory.isNotEmpty) {
        throw Exception('Cannot delete category "${category.name}" because it is used by ${productsUsingCategory.length} product(s).');
      }
      await _categoryBox.delete(id);
    }
  }

  Future<void> close() async {
    await Hive.close();
  }
}