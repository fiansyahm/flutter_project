// screens/product_screen.dart
import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/product.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  List<Product> _products = [];
  final _nameController = TextEditingController();
  final _stockController = TextEditingController();
  final _skuController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _categoryController = TextEditingController();
  final dbHelper = DatabaseHelper.instance; // Use the singleton instance

  @override
  void initState() {
    super.initState();
    _refreshProducts();
  }

  void _refreshProducts() async {
    final data = await dbHelper.getProducts();
    setState(() {
      _products = data;
    });
  }

  void _showForm({Product? product}) {
    if (product != null) {
      _nameController.text = product.name;
      _stockController.text = product.stock.toString();
      _skuController.text = product.sku;
      _purchasePriceController.text = product.purchasePrice.toString();
      _sellingPriceController.text = product.sellingPrice.toString();
      _categoryController.text = product.category;
    } else {
      _nameController.clear();
      _stockController.clear();
      _skuController.clear();
      _purchasePriceController.clear();
      _sellingPriceController.clear();
      _categoryController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Barang'),
              ),
              TextField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stok'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _skuController,
                decoration: const InputDecoration(labelText: 'SKU'),
              ),
              TextField(
                controller: _purchasePriceController,
                decoration: const InputDecoration(labelText: 'Harga Beli'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _sellingPriceController,
                decoration: const InputDecoration(labelText: 'Harga Jual'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Kategori'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final name = _nameController.text;
                  final stock = int.tryParse(_stockController.text) ?? 0;
                  final sku = _skuController.text;
                  final purchasePrice = int.tryParse(_purchasePriceController.text) ?? 0;
                  final sellingPrice = int.tryParse(_sellingPriceController.text) ?? 0;
                  final category = _categoryController.text;

                  if (name.isNotEmpty && sku.isNotEmpty && category.isNotEmpty) {
                    if (product == null) {
                      await dbHelper.insertProduct(
                        Product(
                          name: name,
                          stock: stock,
                          sku: sku,
                          purchasePrice: purchasePrice,
                          sellingPrice: sellingPrice,
                          category: category,
                        ),
                      );
                    } else {
                      await dbHelper.updateProduct(
                        Product(
                          id: product.id,
                          name: name,
                          stock: stock,
                          sku: sku,
                          purchasePrice: purchasePrice,
                          sellingPrice: sellingPrice,
                          category: category,
                        ),
                      );
                    }

                    Navigator.of(context).pop();
                    _refreshProducts();
                  }
                },
                child: Text(product == null ? 'Tambah' : 'Update'),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteProduct(int id) async {
    await dbHelper.deleteProduct(id);
    _refreshProducts();
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Barang/Jasa'),
        backgroundColor: Colors.yellow[700],
        foregroundColor: Colors.black,
      ),
      body: ListView.builder(
        itemCount: _products.length,
        itemBuilder: (ctx, i) {
          final product = _products[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(product.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SKU: ${product.sku}'),
                  Text('Stok: ${product.stock}'),
                  Text('Harga Beli: Rp ${_formatNumber(product.purchasePrice)}'),
                  Text('Harga Jual: Rp ${_formatNumber(product.sellingPrice)}'),
                  Text('Kategori: ${product.category}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showForm(product: product),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteProduct(product.id!),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: Colors.yellow[700],
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }
}