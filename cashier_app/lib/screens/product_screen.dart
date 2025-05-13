import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../db/adapters.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  List<Product> _products = [];
  List<Category> _categories = [];
  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _refreshProducts();
    _loadCategories();
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

  void _showAddCategoryDialog(BuildContext context, Function onCategoryAdded) {
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
                  onCategoryAdded(); // Refresh categories
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

  void _showForm(BuildContext context, Product? product) {
    final _nameController = TextEditingController(text: product?.name ?? '');
    final _stockController = TextEditingController(text: product?.stock.toString() ?? '');
    final _skuController = TextEditingController(text: product?.sku ?? '');
    final _purchasePriceController = TextEditingController(text: product?.purchasePrice.toString() ?? '');
    final _sellingPriceController = TextEditingController(text: product?.sellingPrice.toString() ?? '');
    String? _selectedCategory = product?.category;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(product == null ? 'Tambah Produk' : 'Edit Produk'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Produk'),
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
                        _selectedCategory = newValue;
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
                      _showAddCategoryDialog(context, () {
                        _loadCategories(); // Refresh categories after adding
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
            onPressed: () => Navigator.of(context).pop(),
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

              if (name.isNotEmpty && sku.isNotEmpty && category != null) {
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
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Harap isi semua field dengan benar')),
                );
              }
            },
            child: Text(product == null ? 'Tambah' : 'Update'),
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
              subtitle: Text('Stok: ${product.stock}\nHarga Jual: Rp ${product.sellingPrice}\nKategori: ${product.category}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showForm(context, product),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await dbHelper.deleteProduct(product.id!);
                      _refreshProducts();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(context, null),
        backgroundColor: Colors.yellow[700],
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }
}