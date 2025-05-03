// models/product.dart
class Product {
  final int? id;
  final String name; // Nama Barang
  final int stock; // Stok
  final String sku; // SKU
  final int purchasePrice; // Harga Beli
  final int sellingPrice; // Harga Jual
  final String category; // Kategori

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