import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../db/database_helper.dart';
import '../db/adapters.dart'; // Import Product, PurchaseTransaction, and Cashier from adapters.dart

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  List<Product> _products = [];
  List<Map<String, dynamic>> _cart = [];
  List<Cashier> _cashiers = [];
  Cashier? _selectedCashier;
  final dbHelper = DatabaseHelper.instance;
  int _discount = 0;
  int _tax = 0;
  String _supplier = '-';
  String _paymentMethod = 'Uang Pas';
  final _noteController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _newCashierController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadStoreProfile();
    _loadCashiers();
  }

  @override
  void dispose() {
    _noteController.dispose();
    _storeNameController.dispose();
    _newCashierController.dispose();
    super.dispose();
  }

  void _loadProducts() async {
    final data = await dbHelper.getProducts();
    setState(() {
      _products = data;
    });
  }

  void _loadStoreProfile() async {
    final profile = await dbHelper.getStoreProfile();
    setState(() {
      _storeNameController.text = profile?.storeName ?? 'Unknown Store';
    });
  }

  void _loadCashiers() async {
    final cashiers = await dbHelper.getCashiers();
    setState(() {
      _cashiers = cashiers;
      if (_cashiers.isNotEmpty) {
        _selectedCashier = _cashiers.first; // Default to the first cashier
      }
    });
  }

  void _addToCart(Product product, int quantity) {
    setState(() {
      final existingItemIndex = _cart.indexWhere((item) => item['product'].id == product.id);
      if (existingItemIndex != -1) {
        _cart[existingItemIndex]['quantity'] += quantity;
      } else {
        _cart.add({
          'product': product,
          'quantity': quantity,
        });
      }
    });
  }

  void _updateQuantity(int index, int newQuantity) {
    setState(() {
      if (newQuantity <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index]['quantity'] = newQuantity;
      }
    });
  }

  int _calculateTotal() {
    int subtotal = _cart.fold<int>(0, (int sum, item) {
      final product = item['product'] as Product;
      final quantity = item['quantity'] as int;
      return sum + (product.sellingPrice * quantity);
    });
    int discountAmount = (subtotal * _discount) ~/ 100;
    int taxAmount = (subtotal * _tax) ~/ 100;
    return subtotal - discountAmount + taxAmount;
  }

  void _showAddItemDialog() {
    Product? selectedProduct;
    int quantity = 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tambah Ke Keranjang'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButton<Product>(
                      hint: const Text('Pilih Barang'),
                      value: selectedProduct,
                      onChanged: (Product? newValue) {
                        setDialogState(() {
                          selectedProduct = newValue;
                        });
                      },
                      items: _products.map((Product product) {
                        return DropdownMenuItem<Product>(
                          value: product,
                          child: Text('${product.name} - Rp ${product.sellingPrice}'),
                        );
                      }).toList(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () {
                            setDialogState(() {
                              if (quantity > 1) quantity--;
                            });
                          },
                        ),
                        Text('$quantity'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            setDialogState(() {
                              quantity++;
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedProduct != null) {
                      _addToCart(selectedProduct!, quantity);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
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
                  _loadCashiers(); // Refresh the cashier list
                  _newCashierController.clear();
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

  void _showPaymentDialog() {
    final total = _calculateTotal();
    int cashPaid = total;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
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
                    Text(
                      'Total: Rp ${total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Uang dibayarkan'),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setModalState(() {
                          cashPaid = int.tryParse(value) ?? 0;
                        });
                      },
                      controller: TextEditingController(text: cashPaid.toString()),
                    ),
                    Text(
                      'Kembalian: Rp ${(cashPaid - total).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    DropdownButton<String>(
                      value: _paymentMethod,
                      onChanged: (String? newValue) {
                        setModalState(() {
                          _paymentMethod = newValue!;
                        });
                      },
                      items: ['Uang Pas', 'Lainnya'].map((String method) {
                        return DropdownMenuItem<String>(
                          value: method,
                          child: Text(method),
                        );
                      }).toList(),
                    ),
                    TextField(
                      controller: _noteController,
                      decoration: const InputDecoration(labelText: 'Keterangan'),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            // Update stock
                            for (var item in _cart) {
                              final product = item['product'] as Product;
                              final quantity = item['quantity'] as int;
                              final newStock = (product.stock - quantity) as int;
                              await dbHelper.updateStock(product.id!, newStock);
                            }

                            // Calculate discount and tax
                            int subtotal = _cart.fold<int>(0, (sum, item) {
                              final product = item['product'] as Product;
                              final quantity = item['quantity'] as int;
                              return sum + (product.sellingPrice * quantity);
                            });
                            int discountAmount = (subtotal * _discount) ~/ 100;
                            int taxAmount = (subtotal * _tax) ~/ 100;

                            // Save transaction
                            await dbHelper.insertTransaction(
                              PurchaseTransaction(
                                items: jsonEncode(_cart.map((item) => {
                                  'name': item['product'].name,
                                  'quantity': item['quantity'],
                                  'price': item['product'].sellingPrice,
                                  'purchasePrice': item['product'].purchasePrice,
                                }).toList()),
                                total: total,
                                paymentMethod: _paymentMethod,
                                cashier: _selectedCashier?.name ?? 'Unknown',
                                supplier: _supplier,
                                discount: discountAmount,
                                tax: taxAmount,
                                date: DateTime.now(),
                              ),
                            );

                            // Show receipt
                            Navigator.pop(context);
                            _showReceipt(total, cashPaid);
                          },
                          child: const Text('Simpan'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _generatePdf(int total, int cashPaid) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _storeNameController.text.isEmpty ? 'Unknown Store' : _storeNameController.text,
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('# Invoice Pembelian #', style: const pw.TextStyle(fontSize: 14)),
              pw.Text('Tanggal: ${DateTime.now().toString().substring(0, 19)}'),
              pw.Divider(),
              pw.Text('Detail Barang:', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              ..._cart.map((item) {
                final product = item['product'] as Product;
                final quantity = item['quantity'] as int;
                final itemTotal = product.sellingPrice * quantity;
                return pw.Text(
                  '${product.name}\n$quantity x Rp ${product.sellingPrice.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} = Rp ${itemTotal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                );
              }).toList(),
              pw.Divider(),
              pw.Text(
                'Total Transaksi: Rp ${total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Uang Dibayarkan: Rp ${cashPaid.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
              ),
              pw.Text(
                'Kembalian: Rp ${(cashPaid - total).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
              ),
              pw.Text('Kasir: ${_selectedCashier?.name ?? 'Unknown'}'),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  void _showReceipt(int total, int cashPaid) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Invoice Transaksi'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _storeNameController.text.isEmpty ? 'Unknown Store' : _storeNameController.text,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Text('# Invoice Pembelian #'),
                Text('Tanggal: ${DateTime.now().toString().substring(0, 19)}'),
                const Divider(),
                const Text('Detail Barang:', style: TextStyle(fontWeight: FontWeight.bold)),
                for (var item in _cart)
                  Text(
                    '${item['product'].name}\n${item['quantity']} x Rp ${item['product'].sellingPrice} = Rp ${(item['product'].sellingPrice * item['quantity']).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                  ),
                const Divider(),
                Text(
                  'Total Transaksi: Rp ${total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Uang Dibayarkan: Rp ${cashPaid.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                ),
                Text(
                  'Kembalian: Rp ${(cashPaid - total).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                ),
                Text('Kasir: ${_selectedCashier?.name ?? 'Unknown'}'),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _generatePdf(total, cashPaid);
                      },
                      child: const Text('Print'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _cart.clear();
                          _discount = 0;
                          _tax = 0;
                          _noteController.clear();
                        });
                      },
                      child: const Text('Selesai'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _calculateTotal();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembelian'),
        backgroundColor: Colors.yellow[700],
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          // Add input fields for store name and cashier
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _storeNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Toko',
                    border: OutlineInputBorder(),
                  ),
                  enabled: false, // Make it read-only since it's fetched from DB
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<Cashier>(
                        hint: const Text('Pilih Kasir'),
                        value: _selectedCashier,
                        onChanged: (Cashier? newValue) {
                          setState(() {
                            _selectedCashier = newValue;
                          });
                        },
                        items: _cashiers.map((Cashier cashier) {
                          return DropdownMenuItem<Cashier>(
                            value: cashier,
                            child: Text(cashier.name),
                          );
                        }).toList(),
                        isExpanded: true,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _showAddCashierDialog,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rp ${total.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      _cart.clear();
                    });
                  },
                ),
              ],
            ),
          ),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Text('Semua item'),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTap: _showAddItemDialog,
              child: const Card(
                child: ListTile(
                  leading: Icon(Icons.add),
                  title: Text('Tambah Ke Keranjang'),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _cart.length,
              itemBuilder: (ctx, i) {
                final item = _cart[i];
                final product = item['product'] as Product;
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(product.name),
                    subtitle: Text(
                      '${item['quantity']} x Rp ${product.sellingPrice} = Rp ${(product.sellingPrice * item['quantity']).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () => _updateQuantity(i, item['quantity'] - 1),
                        ),
                        Text('${item['quantity']}'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => _updateQuantity(i, item['quantity'] + 1),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _cart.isNotEmpty ? _showPaymentDialog : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Bayar'),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text('${_cart.length} Item'),
            ],
          ),
        ),
      ),
    );
  }
}