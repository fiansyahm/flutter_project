import 'package:hive/hive.dart';

part 'adapters.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String name;

  @HiveField(2)
  int stock;

  @HiveField(3)
  String sku;

  @HiveField(4)
  int purchasePrice;

  @HiveField(5)
  int sellingPrice;

  @HiveField(6)
  String category;

  Product({
    this.id,
    required this.name,
    required this.stock,
    required this.sku,
    required this.purchasePrice,
    required this.sellingPrice,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'stock': stock,
      'sku': sku,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'category': category,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      stock: map['stock'],
      sku: map['sku'],
      purchasePrice: map['purchasePrice'],
      sellingPrice: map['sellingPrice'],
      category: map['category'],
    );
  }
}

@HiveType(typeId: 1)
class PurchaseTransaction extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String items;

  @HiveField(2)
  int total;

  @HiveField(3)
  String paymentMethod;

  @HiveField(4)
  String cashier;

  @HiveField(5)
  String supplier;

  @HiveField(6)
  int discount;

  @HiveField(7)
  int tax;

  @HiveField(8)
  DateTime date;

  PurchaseTransaction({
    this.id,
    required this.items,
    required this.total,
    required this.paymentMethod,
    required this.cashier,
    required this.supplier,
    required this.discount,
    required this.tax,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items,
      'total': total,
      'paymentMethod': paymentMethod,
      'cashier': cashier,
      'supplier': supplier,
      'discount': discount,
      'tax': tax,
      'date': date.toIso8601String(),
    };
  }

  factory PurchaseTransaction.fromMap(Map<String, dynamic> map) {
    return PurchaseTransaction(
      id: map['id'],
      items: map['items'],
      total: map['total'],
      paymentMethod: map['paymentMethod'],
      cashier: map['cashier'],
      supplier: map['supplier'],
      discount: map['discount'],
      tax: map['tax'],
      date: DateTime.parse(map['date']),
    );
  }
}

@HiveType(typeId: 2)
class Category extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String name;

  Category({
    this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
    );
  }
}

@HiveType(typeId: 3)
class StoreProfile extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String storeName;

  StoreProfile({
    this.id,
    required this.storeName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'storeName': storeName,
    };
  }

  factory StoreProfile.fromMap(Map<String, dynamic> map) {
    return StoreProfile(
      id: map['id'],
      storeName: map['storeName'],
    );
  }
}

@HiveType(typeId: 4)
class Cashier extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  String name;

  Cashier({
    this.id,
    required this.name,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  factory Cashier.fromMap(Map<String, dynamic> map) {
    return Cashier(
      id: map['id'],
      name: map['name'],
    );
  }
}

@HiveType(typeId: 5)
class StockTransaction extends HiveObject {
  @HiveField(0)
  int? id;

  @HiveField(1)
  int productId;

  @HiveField(2)
  String productName;

  @HiveField(3)
  int quantity;

  @HiveField(4)
  String type; // "masuk" or "keluar"

  @HiveField(5)
  DateTime date;

  @HiveField(6)
  String sku;

  StockTransaction({
    this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.type,
    required this.date,
    required this.sku,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'type': type,
      'date': date.toIso8601String(),
      'sku': sku,
    };
  }

  factory StockTransaction.fromMap(Map<String, dynamic> map) {
    return StockTransaction(
      id: map['id'],
      productId: map['productId'],
      productName: map['productName'],
      quantity: map['quantity'],
      type: map['type'],
      date: DateTime.parse(map['date']),
      sku: map['sku'] ?? '', // Fallback for missing sku
    );
  }
}