import 'package:flutter/material.dart';
import 'product_screen.dart';
import 'purchase_screen.dart';
import 'sales_recap_screen.dart';
import 'stock_management_screen.dart';
import 'category_screen.dart';
import 'profile_store_screen.dart';
import 'cashier_management_screen.dart';
import '../db/database_helper.dart';
import '../db/adapters.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _storeName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStoreProfile();
  }

  void _loadStoreProfile() async {
    final profile = await DatabaseHelper.instance.getStoreProfile();
    setState(() {
      _storeName = profile?.storeName ?? 'Aplikasi Kasir'; // Generic fallback
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isLoading ? const Text('Memuat...') : Text(_storeName ?? 'Aplikasi Kasir'),
        backgroundColor: Colors.yellow[700],
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileStoreScreen()),
              ).then((_) {
                _loadStoreProfile(); // Refresh store name after editing
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildFeatureButton(
              context,
              icon: Icons.store,
              label: 'Barang/Jasa',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductScreen()),
                );
              },
            ),
            _buildFeatureButton(
              context,
              icon: Icons.category,
              label: 'Kategori Barang',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoryScreen()),
                );
              },
            ),
            _buildFeatureButton(
              context,
              icon: Icons.inventory,
              label: 'Manajemen Stok',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StockManagementScreen()),
                );
              },
            ),
            _buildFeatureButton(
              context,
              icon: Icons.shopping_cart,
              label: 'Pembelian Barang',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PurchaseScreen()),
                );
              },
            ),
            _buildFeatureButton(
              context,
              icon: Icons.bar_chart,
              label: 'Rekap Penjualan',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SalesRecapScreen()),
                );
              },
            ),
            _buildFeatureButton(
              context,
              icon: Icons.person,
              label: 'Manajemen Kasir',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CashierManagementScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: Colors.yellow[700]),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}