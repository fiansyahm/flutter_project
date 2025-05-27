import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../db/adapters.dart';

class StockManagementScreen extends StatefulWidget {
  const StockManagementScreen({super.key});

  @override
  State<StockManagementScreen> createState() => _StockManagementScreenState();
}

class _StockManagementScreenState extends State<StockManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Product> _products = [];
  List<StockTransaction> _transactions = [];
  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProducts();
    _loadTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadProducts() async {
    final data = await dbHelper.getProducts();
    setState(() {
      _products = data;
    });
  }

  void _loadTransactions() async {
    final data = await dbHelper.getStockTransactions();
    setState(() {
      _transactions = data;
    });
  }

  Future<void> _updateStock(int productId, int change, String type) async {
    final product = _products.firstWhere((p) => p.id == productId);
    final newStock = product.stock + change;
    if (newStock >= 0) {
      await dbHelper.updateStock(productId, newStock);
      await dbHelper.insertStockTransaction(
        StockTransaction(
          productId: productId,
          productName: product.name,
          quantity: change.abs(),
          type: type,
          date: DateTime.now(),
          sku: product.sku,
        ),
      );
      _loadProducts();
      _loadTransactions();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok tidak boleh negatif')),
      );
    }
  }

  void _showQuantityDialog(int productId, IconData icon, String type) {
    final _quantityController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Masukkan Jumlah ${type == 'masuk' ? 'Masuk' : 'Keluar'}'),
        content: TextField(
          controller: _quantityController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Jumlah'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(_quantityController.text) ?? 0;
              if (quantity > 0) {
                _updateStock(productId, type == 'masuk' ? quantity : -quantity, type);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Jumlah harus lebih dari 0')),
                );
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Stok'),
        backgroundColor: Colors.yellow[700],
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Stok'),
            Tab(text: 'Barang Masuk'),
            Tab(text: 'Barang Keluar'),
          ],
          labelColor: Colors.black,
          indicatorColor: Colors.black,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Stok Tab
          _products.isEmpty
              ? const Center(child: Text('Tidak ada produk tersedia'))
              : ListView.builder(
            itemCount: _products.length,
            itemBuilder: (ctx, i) {
              final product = _products[i];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(product.name),
                  subtitle: Text(
                    'SKU: ${product.sku}\nKategori: ${product.category}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, color: Colors.red),
                        onPressed: () => _showQuantityDialog(product.id!, Icons.remove, 'keluar'),
                      ),
                      Text(
                        '${product.stock}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.green),
                        onPressed: () => _showQuantityDialog(product.id!, Icons.add, 'masuk'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Barang Masuk Tab
          _transactions.isEmpty
              ? const Center(child: Text('Tidak ada barang masuk'))
              : ListView.builder(
            itemCount: _transactions.length,
            itemBuilder: (ctx, i) {
              final transaction = _transactions[i];
              if (transaction.type == 'masuk') {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(transaction.productName),
                    subtitle: Text(
                      'SKU: ${transaction.sku}\n'
                          'Jumlah: ${transaction.quantity}\n'
                          'Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(transaction.date)}',
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          // Barang Keluar Tab
          _transactions.isEmpty
              ? const Center(child: Text('Tidak ada barang keluar'))
              : ListView.builder(
            itemCount: _transactions.length, // Changed from _products.length
            itemBuilder: (ctx, i) {
              final transaction = _transactions[i];
              if (transaction.type == 'keluar') {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(transaction.productName),
                    subtitle: Text(
                      'SKU: ${transaction.sku}\n'
                          'Jumlah: ${transaction.quantity}\n'
                          'Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(transaction.date)}',
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }
}