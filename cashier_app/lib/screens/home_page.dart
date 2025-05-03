import 'package:flutter/material.dart';
import 'product_screen.dart';
import 'purchase_screen.dart';
import 'sales_recap_screen.dart';
import 'stock_management_screen.dart';
import 'category_screen.dart'; // Import the new CategoryScreen

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Karen Cashier'),
        backgroundColor: Colors.yellow[700],
        foregroundColor: Colors.black,
      ),
      body: Padding(
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