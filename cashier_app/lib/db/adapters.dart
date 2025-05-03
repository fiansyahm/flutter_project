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