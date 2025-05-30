import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../db/database_helper.dart';
import '../db/adapters.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> with SingleTickerProviderStateMixin {
  List<Product> _products = [];
  List<Category> _categories = [];
  final DatabaseHelper dbHelper = DatabaseHelper.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refreshProducts();
    _loadCategories();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshProducts() async {
    final data = await dbHelper.getProducts();
    setState(() {
      _products = data;
    });
  }

  void _loadCategories() async {
    final data = await dbHelper.getCategories();
    setState(() {
      _categories = data;
    });
  }

  void _showAddCategoryDialog(BuildContext context, Function(String) onCategoryAdded) {
    final _categoryNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Kategori Baru'),
        content: TextField(
          controller: _categoryNameController,
          decoration: const InputDecoration(labelText: 'Nama Kategori'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _categoryNameController.text.trim();
              if (name.isNotEmpty) {
                try {
                  await dbHelper.insertCategory(Category(name: name));
                  Navigator.of(context).pop();
                  onCategoryAdded(name);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kategori berhasil ditambahkan')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama kategori tidak boleh kosong')),
                );
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  Future<void> _scanBarcode() async {
    try {
      final result = await BarcodeScanner.scan();
      if (result.rawContent.isNotEmpty) {
        _showForm(context, null, scannedSku: result.rawContent);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error scanning: $e')),
      );
    }
  }

  void _showForm(BuildContext context, Product? product, {String? scannedSku}) {
    final _nameController = TextEditingController(text: product?.name ?? '');
    final _stockController = TextEditingController(text: product?.stock.toString() ?? '');
    final _skuController = TextEditingController(text: product?.sku ?? scannedSku ?? '');
    final _purchasePriceController = TextEditingController(text: product?.purchasePrice.toString() ?? '');
    final _sellingPriceController = TextEditingController(text: product?.sellingPrice.toString() ?? '');
    String? _selectedCategory = product?.category;
    final originalStock = product?.stock ?? 0;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(product == null ? 'Tambah Produk' : 'Edit Produk'),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nama Produk'),
                  ),
                  TextField(
                    controller: _skuController,
                    decoration: const InputDecoration(labelText: 'SKU'),
                  ),
                  TextField(
                    controller: _stockController,
                    decoration: const InputDecoration(labelText: 'Stok'),
                    keyboardType: TextInputType.number,
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
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Kategori'),
                          value: _selectedCategory,
                          items: _categories.map((Category category) {
                            return DropdownMenuItem<String>(
                              value: category.name,
                              child: Text(category.name),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setDialogState(() {
                              _selectedCategory = newValue;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Pilih kategori';
                            }
                            return null;
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.green),
                        onPressed: () {
                          _showAddCategoryDialog(dialogContext, (newCategory) {
                            setState(() {
                              _categories.add(Category(name: newCategory));
                            });
                            setDialogState(() {
                              _selectedCategory = newCategory;
                            });
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = _nameController.text;
                  final stock = int.tryParse(_stockController.text) ?? 0;
                  final sku = _skuController.text;
                  final purchasePrice = int.tryParse(_purchasePriceController.text) ?? 0;
                  final sellingPrice = int.tryParse(_sellingPriceController.text) ?? 0;
                  final category = _selectedCategory;

                  // Check for duplicate SKU
                  final existingProduct = _products.firstWhere(
                        (p) => p.sku == sku && (product == null || p.id != product.id),
                    orElse: () => Product(id: null, name: '', stock: 0, sku: '', purchasePrice: 0, sellingPrice: 0, category: ''),
                  );
                  if (existingProduct.sku.isNotEmpty) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('SKU sudah digunakan')),
                    );
                    return;
                  }

                  if (name.isNotEmpty && sku.isNotEmpty && category != null) {
                    if (product == null) {
                      final newProductId = await dbHelper.insertProduct(
                        Product(
                          id: null,
                          name: name,
                          stock: stock,
                          sku: sku,
                          purchasePrice: purchasePrice,
                          sellingPrice: sellingPrice,
                          category: category,
                        ),
                      );
                      Navigator.of(dialogContext).pop();
                      _refreshProducts();
                      if (stock > 0) {
                        await dbHelper.insertStockTransaction(
                          StockTransaction(
                            id: null,
                            productId: newProductId,
                            productName: name,
                            quantity: stock,
                            type: 'masuk',
                            date: DateTime.now(),
                            sku: sku,
                          ),
                        );
                        _showBarangMasukDialog(context, name, sku, stock);
                      }
                    } else {
                      if (stock != originalStock) {
                        await dbHelper.insertStockTransaction(
                          StockTransaction(
                            id: null,
                            productId: product.id!,
                            productName: name,
                            quantity: stock - originalStock,
                            type: 'edit',
                            date: DateTime.now(),
                            sku: sku,
                          ),
                        );
                      }
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
                      Navigator.of(dialogContext).pop();
                      _refreshProducts();
                    }
                  } else {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      const SnackBar(content: Text('Harap isi semua field dengan benar')),
                    );
                  }
                },
                child: Text(product == null ? 'Tambah' : 'Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBarangMasukDialog(BuildContext parentContext, String name, String sku, int stock) {
    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Barang Masuk'),
        content: SingleChildScrollView(
          child: Text(
            'Nama: $name\n'
                'SKU: $sku\n'
                'Stok: $stock\n'
                'Barang Masuk',
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text(
          'Nama: ${product.name}\n'
              'SKU: ${product.sku}\n'
              'Stok: ${product.stock}\n'
              'Barang Keluar',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (product.stock > 0) {
                await dbHelper.insertStockTransaction(
                  StockTransaction(
                    id: null,
                    productId: product.id!,
                    productName: product.name,
                    quantity: product.stock,
                    type: 'keluar',
                    date: DateTime.now(),
                    sku: product.sku,
                  ),
                );
              }
              await dbHelper.deleteProduct(product.id!);
              Navigator.of(context).pop();
              _refreshProducts();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Produk berhasil dihapus')),
              );
            },
            child: const Text('Ya'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Produk'),
        backgroundColor: Colors.yellow[700],
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Stok'),
            Tab(text: 'Riwayat'),
          ],
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.black,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Stok (Product List)
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
                    'SKU: ${product.sku}\n'
                        'Stok: ${product.stock}\n'
                        'Harga Beli: Rp ${product.purchasePrice}\n'
                        'Harga Jual: Rp ${product.sellingPrice}\n'
                        'Kategori: ${product.category}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showForm(context, product),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _showDeleteConfirmationDialog(context, product),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Tab 2: Riwayat (Stock Edit History)
          const StockHistoryScreen(),
        ],
      ),
      floatingActionButton: PopupMenuButton<String>(
        icon: const Icon(Icons.add, color: Colors.black),
        color: Colors.yellow[700],
        onSelected: (String value) {
          if (value == 'form') {
            _showForm(context, null);
          } else if (value == 'scan') {
            _scanBarcode();
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          const PopupMenuItem<String>(
            value: 'form',
            child: ListTile(
              leading: Icon(Icons.edit),
              title: Text('Form'),
            ),
          ),
          const PopupMenuItem<String>(
            value: 'scan',
            child: ListTile(
              leading: Icon(Icons.qr_code_scanner),
              title: Text('Scan'),
            ),
          ),
        ],
      ),
    );
  }
}

class StockHistoryScreen extends StatelessWidget {
  const StockHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<StockTransaction>>(
      future: DatabaseHelper.instance.getStockTransactions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        final transactions = snapshot.data?.where((t) => t.type == 'edit').toList() ?? [];
        if (transactions.isEmpty) {
          return const Center(child: Text('Tidak ada riwayat edit stok'));
        }
        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (ctx, i) {
            final transaction = transactions[i];
            return ListTile(
              title: Text('Edit Stok - ${transaction.productName}'),
              subtitle: Text(
                'SKU: ${transaction.sku}\n'
                    'Perubahan: ${transaction.quantity > 0 ? '+' : ''}${transaction.quantity}\n'
                    'Tanggal: ${DateFormat('yyyy-MM-dd HH:mm').format(transaction.date)}',
              ),
            );
          },
        );
      },
    );
  }
}