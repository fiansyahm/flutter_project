import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

// HomePage with BottomNavigationBar
class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      PriceUpdateFormPage(),
      PriceUpdateListPage(),
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: 'Form Tagihan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Daftar Tagihan',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}

// Page 1: Price Update Form
class PriceUpdateFormPage extends StatefulWidget {
  final Map<String, dynamic>? record;
  final String? editingKey;

  PriceUpdateFormPage({this.record, this.editingKey});

  @override
  _PriceUpdateFormPageState createState() => _PriceUpdateFormPageState();
}

class _PriceUpdateFormPageState extends State<PriceUpdateFormPage> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final _nameController = TextEditingController();
  final _skuController = TextEditingController();
  final _regionController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _cashierController = TextEditingController();
  String _paymentMethod = 'Tunai';
  String _editingKey = '';

  String formatRupiah(String amount) {
    if (amount.isEmpty) return "Rp 0";
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(int.tryParse(amount.replaceAll('.', '')) ?? 0);
  }

  @override
  void initState() {
    super.initState();
    if (widget.record != null && widget.editingKey != null) {
      _editingKey = widget.editingKey!;
      _nameController.text = widget.record!['name'];
      _skuController.text = widget.record!['sku'];
      _regionController.text = widget.record!['region'];
      _amountController.text = widget.record!['amount'];
      _dateController.text = widget.record!['date'];
      _timeController.text = widget.record!['time'];
      _paymentMethod = widget.record!['payment'];
      _cashierController.text = widget.record!['cashier'];
    }

    _amountController.addListener(() {
      final text = _amountController.text;
      final formatted = _formatCurrency(text.replaceAll('.', ''));
      if (_amountController.text != formatted) {
        _amountController.value = _amountController.value.copyWith(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    });
  }

  String _formatCurrency(String text) {
    return text;
  }

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      _dateController.text = DateFormat('dd-MM-yyyy').format(pickedDate);
    }
  }

  Future<void> _selectDate2() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      _timeController.text = DateFormat('dd-MM-yyyy').format(pickedDate);
    }
  }

  void _addOrUpdateRecord() {
    if (_formKey.currentState!.validate()) {
      final newRecord = {
        'date': _dateController.text,
        'time': _timeController.text,
        'name': _nameController.text,
        'sku': _skuController.text,
        'region': _regionController.text,
        'amount': _amountController.text,
        'payment': _paymentMethod,
        'cashier': _cashierController.text,
      };

      if (_editingKey.isEmpty) {
        _database.child('records_tagihan').push().set(newRecord).then((_) {
          _clearForm();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload data berhasil')),
          );
        });
      } else {
        _database.child('records_tagihan').child(_editingKey).set(newRecord).then((_) {
          _clearForm();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload data berhasil')),
          );
          Navigator.pop(context); // Return to list page after editing
        });
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _skuController.clear();
    _regionController.clear();
    _amountController.clear();
    _dateController.clear();
    _timeController.clear();
    _cashierController.clear();
    _paymentMethod = 'Tunai';
    _editingKey = '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Form Tagihan', style: TextStyle(fontSize: 16)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Biaya Pembayaran Tagihan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Tanggal',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: _selectDate,
                  ),
                ),
                readOnly: true,
                validator: (value) => value == null || value.isEmpty ? 'Tanggal tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Produk'),
                validator: (value) => value == null || value.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _skuController,
                decoration: InputDecoration(labelText: 'No Produk'),
                validator: (value) => value == null || value.isEmpty ? 'No Produk tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _cashierController,
                decoration: InputDecoration(labelText: 'Agent'),
                validator: (value) => value == null || value.isEmpty ? 'Agent tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _regionController,
                decoration: InputDecoration(labelText: 'Lokasi'),
                validator: (value) => value == null || value.isEmpty ? 'Lokasi tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Nilai (Rp)'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) => value == null || value.isEmpty ? 'Nominal tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _timeController,
                decoration: InputDecoration(
                  labelText: 'Jatuh Tempo',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: _selectDate2,
                  ),
                ),
                readOnly: true,
                validator: (value) => value == null || value.isEmpty ? 'Jatuh Tempo tidak boleh kosong' : null,
              ),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: InputDecoration(labelText: 'Pembayaran Via'),
                items: ['Credit Card', 'Tunai', 'Transfer']
                    .map((method) => DropdownMenuItem(value: method, child: Text(method)))
                    .toList(),
                onChanged: (value) => setState(() => _paymentMethod = value!),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _addOrUpdateRecord,
                child: Text(_editingKey.isEmpty ? 'Simpan' : 'Update'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Page 2: Price Update List
class PriceUpdateListPage extends StatefulWidget {
  @override
  _PriceUpdateListPageState createState() => _PriceUpdateListPageState();
}

class _PriceUpdateListPageState extends State<PriceUpdateListPage> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  String formatRupiah(String amount) {
    if (amount.isEmpty) return "Rp 0";
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(int.tryParse(amount.replaceAll('.', '')) ?? 0);
  }

  Future<void> _generateTransactionPDF(Map<String, dynamic> record) async {
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(height: 10),
            pw.Text('Produk: ${record['name']}', style: pw.TextStyle(fontSize: 10)),
            pw.Text('Lokasi: ${record['region']}', style: pw.TextStyle(fontSize: 10)),
            pw.Text('Nilai: ${formatRupiah(record['amount'])}', style: pw.TextStyle(fontSize: 10)),
            pw.Text('Tanggal: ${record['date']}', style: pw.TextStyle(fontSize: 10)),
            pw.Text('Jatuh Tempo: ${record['time']}', style: pw.TextStyle(fontSize: 10)),
            pw.Text('Pembayaran Via: ${record['payment']}', style: pw.TextStyle(fontSize: 10)),
            pw.Text('Agent: ${record['cashier']}', style: pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 20),
          ],
        );
      },
    ));
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> generatePriceUpdateReport(BuildContext context) async {
    final DateTimeRange? dateRange = await showDateRangePicker(
      context: context,
      initialDateRange: null,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (dateRange != null) {
      final startDate = dateRange.start;
      final endDate = dateRange.end;
      final snapshot = await _database.child('records_tagihan').get();
      if (snapshot.exists) {
        final allRecords = Map<String, dynamic>.from(snapshot.value as Map);
        final filteredRecords = allRecords.entries.where((entry) {
          final recordDate = DateFormat('dd-MM-yyyy').parse(entry.value['date']);
          return recordDate.isAfter(startDate.subtract(Duration(days: 1))) &&
              recordDate.isBefore(endDate.add(Duration(days: 1)));
        }).toList();

        if (filteredRecords.isNotEmpty) {
          final pdf = pw.Document();
          int totalDonatur = filteredRecords.length;
          final totalUang = filteredRecords.fold(0, (sum, entry) {
            final record = Map<String, dynamic>.from(entry.value);
            final amount = int.tryParse(record['amount'].replaceAll('.', '')) ?? 0;
            return sum + amount;
          });

          pdf.addPage(
            pw.Page(
              build: (pw.Context context) {
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Laporan Tagihan', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Periode: ${DateFormat('dd-MM-yyyy').format(startDate)} - ${DateFormat('dd-MM-yyyy').format(endDate)}'),
                    pw.SizedBox(height: 10),
                    pw.Table(
                      border: pw.TableBorder.all(),
                      columnWidths: {
                        0: pw.FlexColumnWidth(0.5),
                        1: pw.FlexColumnWidth(1.5),
                        2: pw.FlexColumnWidth(1),
                        3: pw.FlexColumnWidth(1.5),
                        4: pw.FlexColumnWidth(1.25),
                        5: pw.FlexColumnWidth(1.25),
                        6: pw.FlexColumnWidth(1.5),
                      },
                      children: [
                        pw.TableRow(
                          children: [
                            pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('No')),
                            pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Produk')),
                            pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Lokasi')),
                            pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Nilai')),
                            pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Tanggal')),
                            pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Pembayaran Via')),
                            pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Agent')),
                          ],
                        ),
                        ...filteredRecords.map((entry) {
                          final record = Map<String, dynamic>.from(entry.value);
                          return pw.TableRow(
                            children: [
                              pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text((filteredRecords.indexOf(entry) + 1).toString())),
                              pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text(record['name'] ?? '-')),
                              pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text(record['region'] ?? '-')),
                              pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text(formatRupiah(record['amount'] ?? '0'))),
                              pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text(record['date'] ?? '-')),
                              pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text(record['payment'] ?? '-')),
                              pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text(record['cashier'] ?? '-')),
                            ],
                          );
                        }),
                      ],
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text('Jumlah Transaksi: $totalDonatur', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Total Tagihan: ${formatRupiah(totalUang.toString())}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                  ],
                );
              },
            ),
          );
          await Printing.layoutPdf(onLayout: (format) async => pdf.save());
        }
      }
    }
  }

  void _deleteRecord(String key) {
    _database.child('records_tagihan').child(key).remove().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Record deleted successfully')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting record: $error')),
      );
    });
  }

  void _editRecord(Map<String, dynamic> record, String key) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PriceUpdateFormPage(
          record: record,
          editingKey: key,
        ),
      ),
    );
  }

  Future<void> _resetDatabase() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Reset Database'),
        content: Text('Are you sure you want to reset the database? All data will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Reset'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _database.child('records_tagihan').remove();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Database has been reset')),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Tagihan', style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: Icon(Icons.print),
            onPressed: () => generatePriceUpdateReport(context),
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Reset Database',
            onPressed: _resetDatabase,
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _database.child('records_tagihan').onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            final records = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
            if (records.isEmpty) {
              return Center(child: Text('Belum ada data', style: TextStyle(fontSize: 16)));
            }
            return ListView.builder(
              physics: AlwaysScrollableScrollPhysics(),
              itemCount: records.keys.length,
              itemBuilder: (context, index) {
                final key = records.keys.elementAt(index);
                final record = Map<String, dynamic>.from(records[key]);
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: EdgeInsets.all(10.0),
                    title: Text(
                      '${record['name']} - ${record['region']}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('No Produk: ${record['sku']}'),
                        Text('Nilai: ${formatRupiah(record['amount'])}'),
                        Text('Tanggal: ${record['date']}'),
                        Text('Jatuh Tempo: ${record['time']}'),
                        Text('Pembayaran: ${record['payment']}'),
                        Text('Agent: ${record['cashier']}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editRecord(record, key),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteRecord(key),
                        ),
                        IconButton(
                          icon: Icon(Icons.print, color: Colors.green),
                          onPressed: () => _generateTransactionPDF(record),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return Center(child: Text('Belum ada data', style: TextStyle(fontSize: 16)));
          }
        },
      ),
    );
  }
}