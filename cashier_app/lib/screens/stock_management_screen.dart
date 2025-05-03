import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../db/adapters.dart'; // Updated import to use Product from adapters.dart

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> {
  List<Product> _products = [];
  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  void _loadProducts() async {
    final data = await dbHelper.getProducts();
    setState(() {
      _products = data;
    });
  }

  void _updateStock(int productId, int newStock) async {
    await dbHelper.updateStock(productId, newStock);
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Stok'),
        backgroundColor: Colors.yellow[700],
        foregroundColor: Colors.black,
      ),
      body: _products.isEmpty
          ? const Center(child: Text('Tidak ada produk tersedia'))
          : ListView.builder(
        itemCount: _products.length,
        itemBuilder: (ctx, i) {
          final product = _products[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(product.name),
              subtitle: Text('SKU: ${product.sku}\nKategori: ${product.category}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, color: Colors.red),
                    onPressed: () {
                      if (product.stock > 0) {
                        _updateStock(product.id!, product.stock - 1);
                      }
                    },
                  ),
                  Text(
                    '${product.stock}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.green),
                    onPressed: () {
                      _updateStock(product.id!, product.stock + 1);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}