// screens/category_screen.dart
import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../db/adapters.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  List<Category> _categories = [];
  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _refreshCategories();
  }

  void _refreshCategories() async {
    final data = await dbHelper.getCategories();
    setState(() {
      _categories = data;
    });
  }

  void _showForm(BuildContext context, Category? category) {
    final _nameController = TextEditingController(text: category?.name ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(category == null ? 'Tambah Kategori' : 'Edit Kategori'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Nama Kategori'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = _nameController.text.trim();
              if (name.isNotEmpty) {
                try {
                  if (category == null) {
                    await dbHelper.insertCategory(
                      Category(name: name),
                    );
                  } else {
                    await dbHelper.updateCategory(
                      Category(id: category.id, name: name),
                    );
                  }
                  Navigator.of(context).pop();
                  _refreshCategories();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: Text(category == null ? 'Tambah' : 'Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Kategori'),
        backgroundColor: Colors.yellow[700],
        foregroundColor: Colors.black,
      ),
      body: _categories.isEmpty
          ? const Center(child: Text('Tidak ada kategori tersedia'))
          : ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (ctx, i) {
          final category = _categories[i];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(category.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showForm(context, category),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      try {
                        await dbHelper.deleteCategory(category.id!);
                        _refreshCategories();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
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