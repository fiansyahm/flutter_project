import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../db/adapters.dart';

class CashierManagementScreen extends StatefulWidget {
  const CashierManagementScreen({super.key});

  @override
  State<CashierManagementScreen> createState() => _CashierManagementScreenState();
}

class _CashierManagementScreenState extends State<CashierManagementScreen> {
  List<Cashier> _cashiers = [];
  final dbHelper = DatabaseHelper.instance;
  final _newCashierController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCashiers();
  }

  @override
  void dispose() {
    _newCashierController.dispose();
    super.dispose();
  }

  void _loadCashiers() async {
    final cashiers = await dbHelper.getCashiers();
    setState(() {
      _cashiers = cashiers;
    });
  }

  void _showAddCashierDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Kasir'),
          content: TextField(
            controller: _newCashierController,
            decoration: const InputDecoration(
              labelText: 'Nama Kasir',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final cashierName = _newCashierController.text.trim();
                if (cashierName.isNotEmpty) {
                  final newCashier = Cashier(name: cashierName);
                  await dbHelper.insertCashier(newCashier);
                  _newCashierController.clear();
                  _loadCashiers(); // Refresh the list
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nama kasir tidak boleh kosong')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showEditCashierDialog(Cashier cashier) {
    _newCashierController.text = cashier.name;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Kasir'),
          content: TextField(
            controller: _newCashierController,
            decoration: const InputDecoration(
              labelText: 'Nama Kasir',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final updatedName = _newCashierController.text.trim();
                if (updatedName.isNotEmpty) {
                  cashier.name = updatedName;
                  await dbHelper.updateCashier(cashier);
                  _newCashierController.clear();
                  _loadCashiers(); // Refresh the list
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nama kasir tidak boleh kosong')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(Cashier cashier) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus kasir "${cashier.name}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (cashier.id != null) {
                  try {
                    await dbHelper.deleteCashier(cashier.id!);
                    _loadCashiers(); // Refresh the list
                    Navigator.pop(context);
                  } catch (e) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Kasir'),
        backgroundColor: Colors.yellow[700],
        foregroundColor: Colors.black,
      ),
      body: _cashiers.isEmpty
          ? const Center(child: Text('Belum ada kasir. Tambahkan kasir baru.'))
          : ListView.builder(
        itemCount: _cashiers.length,
        itemBuilder: (context, index) {
          final cashier = _cashiers[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              title: Text(cashier.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _showEditCashierDialog(cashier),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _showDeleteConfirmation(cashier),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCashierDialog,
        backgroundColor: Colors.yellow[700],
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }
}