import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../db/adapters.dart';

class CashierScreen extends StatefulWidget {
  const CashierScreen({super.key});

  @override
  State<CashierScreen> createState() => _CashierScreenState();
}

class _CashierScreenState extends State<CashierScreen> {
  final dbHelper = DatabaseHelper.instance;
  List<Product> _products = [];
  List<Map<String, dynamic>> _cart = [];
  final _searchController = TextEditingController();

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

  void _addToCart(Product product) {
    setState(() {
      final cartItem = _cart.firstWhere(
            (item) => item['product'].id == product.id,
        orElse: () => {'product': product, 'quantity': 0, 'total': 0},
      );
      cartItem['quantity']++;
      cartItem['total'] = cartItem['quantity'] * product.sellingPrice;
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      if (_cart[index]['quantity'] > 1) {
        _cart[index]['quantity']--;
        _cart[index]['total'] = _cart[index]['quantity'] * _cart[index]['product'].sellingPrice;
      } else {
        _cart.removeAt(index);
      }
    });
  }

  int _getTotal() {
    return _cart.fold<int>(0, (sum, item) => sum + (item['total'] as int));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembelian'),
        backgroundColor: Colors.yellow[700],
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Cari Barang',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Add search logic if needed
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _products.length,
              itemBuilder: (ctx, i) {
                final product = _products[i];
                return ListTile(
                  title: Text(product.name),
                  subtitle: Text('Rp ${product.sellingPrice}'),
                  trailing: ElevatedButton(
                    onPressed: () => _addToCart(product),
                    child: const Text('Tambah'),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (_cart.isNotEmpty)
                  ..._cart.map((item) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item['product'].name),
                        Text('Rp ${item['total']}'),
                        IconButton(
                          icon: const Icon(Icons.remove, color: Colors.red),
                          onPressed: () => _removeFromCart(_cart.indexOf(item)),
                        ),
                      ],
                    );
                  }).toList(),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Rp ${_getTotal()}'), // Updated to use _getTotal()
                    ElevatedButton(
                      onPressed: _cart.isEmpty ? null : () {
                        // Add payment logic here
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pembayaran berhasil')),
                        );
                      },
                      child: const Text('Bayar'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _cart.clear();
                    });
                  },
                  child: const Text('Semua Item'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}