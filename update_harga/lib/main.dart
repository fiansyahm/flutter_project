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
      home: ReceiptApp(),
    );
  }
}

class ReceiptApp extends StatefulWidget {
  @override
  _ReceiptAppState createState() => _ReceiptAppState();
}

class _ReceiptAppState extends State<ReceiptApp> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final _dateController = TextEditingController();
  String _userType='Customer';
  final _nameController = TextEditingController();
  final _fullnameController = TextEditingController();
  final _skuController = TextEditingController();
  final _amountController = TextEditingController();
  String _programMethod = 'MI';
  String _editingKey = '';

  // Fungsi untuk memformat angka menjadi format Rupiah
  String formatRupiah(String amount) {
    if (amount.isEmpty) return "Rp 0";
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(int.tryParse(amount.replaceAll('.', '')) ?? 0);
  }

  @override
  void initState() {
    super.initState();

    // Menambahkan pemformatan untuk amountController
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

  // Fungsi untuk memformat input dengan titik setiap 3 angka
  String _formatCurrency(String text) {
    // final amount = int.tryParse(text) ?? 0;
    // final formatted = NumberFormat('#,###').format(amount);  // Menambahkan pemisah ribuan
    // return formatted;
    return text;
  }

  Future<void> _generateTransactionPDF(Map<String, dynamic> record) async {
    final pdf = pw.Document();

    pdf.addPage(pw.Page(
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // pw.Text('YAYASAN BUDI DHARMA KIRT', style: pw.TextStyle(fontSize: 12)),
            // pw.Text('Kelenteng Hok Heng Kiong Kota Tangerang', style: pw.TextStyle(fontSize: 10)),
            // pw.Text('WA 0838-0870-2766(Sukardi/Ang Tek Kang)', style: pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 10),
            pw.Text('Tanggal: ${record['date']}', style: pw.TextStyle(fontSize: 10)),
            pw.Text('Pilihan: ${record['user']}', style: pw.TextStyle(fontSize: 10)),
            pw.Text('Item: ${record['name']}', style: pw.TextStyle(fontSize: 10)),
            pw.Text('Nama: ${record['fullname']}', style: pw.TextStyle(fontSize: 10)),
            pw.Text('Kode: ${record['sku']}', style: pw.TextStyle(fontSize: 10)),
            pw.Text('Harga: ${formatRupiah(record['amount'])}', style: pw.TextStyle(fontSize: 10)),
            pw.Text('Program: ${record['program']}', style: pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 20),
            // pw.Text('REK BCA', style: pw.TextStyle(fontSize: 10)),
            // pw.Text('3990345731', style: pw.TextStyle(fontSize: 10)),
            // pw.Text('A/N YAYASAN BUDI DHARMA KIRT', style: pw.TextStyle(fontSize: 10)),
            // pw.SizedBox(height: 20),
            // pw.Text('Sumbangan yang Anda berikan telah kami terima.', style: pw.TextStyle(fontSize: 10)),
            // pw.Text('Kami mengucapkan terimakasih sebesar-besarnya', style: pw.TextStyle(fontSize: 10)),
            // pw.Text('dan semoga Anda selalu dilimpahi dengan kebaikan.', style: pw.TextStyle(fontSize: 10)),
          ],
        );
      },
    ));

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Future<void> generatePriceUpdateReport(BuildContext context) async {
    // Pilih rentang tanggal menggunakan showDateRangePicker
    final DateTimeRange? dateRange = await showDateRangePicker(
      context: context,
      initialDateRange: null,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (dateRange != null) {
      final startDate = dateRange.start;
      final endDate = dateRange.end;

      // Fetch daftar fullname dari Firebase
      final snapshot = await _database.child('records_price_update').get();
      if (snapshot.exists) {
        final allRecords = Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
        final fullnames = allRecords.values
            .map((record) => (record as Map<dynamic, dynamic>)['fullname']?.toString() ?? '-')
            .toSet()
            .toList();

        // Tambahkan opsi "All" ke daftar nama
        fullnames.insert(0, 'All');

        // Tampilkan dialog pilihan fullname
        String? selectedFullname = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Pilih Fullname'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: fullnames.length,
                  itemBuilder: (context, index) {
                    final fullname = fullnames[index];
                    return ListTile(
                      title: Text(fullname),
                      onTap: () {
                        Navigator.of(context).pop(fullname);
                      },
                    );
                  },
                ),
              ),
            );
          },
        );

        if (selectedFullname != null) {
          // Filter data berdasarkan rentang tanggal dan fullname yang dipilih
          final filteredRecords = allRecords.entries.where((entry) {
            final record = Map<String, dynamic>.from(entry.value);
            final recordDate = DateFormat('dd-MM-yyyy').parse(record['date']);
            return (selectedFullname == 'All' || record['fullname'] == selectedFullname) &&
                recordDate.isAfter(startDate.subtract(Duration(days: 1))) &&
                recordDate.isBefore(endDate.add(Duration(days: 1)));
          }).toList();

          if (filteredRecords.isNotEmpty) {
            final pdf = pw.Document();

            // Hitung total item dan total harga
            int totalItems = filteredRecords.length;
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
                      pw.Text('Laporan Update Harga', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Periode: ${DateFormat('dd-MM-yyyy').format(startDate)} - ${DateFormat('dd-MM-yyyy').format(endDate)}'),
                      pw.Text('Fullname: $selectedFullname'),
                      pw.SizedBox(height: 10),
                      pw.Table(
                        border: pw.TableBorder.all(),
                        columnWidths: {
                          0: pw.FlexColumnWidth(0.5),
                          1: pw.FlexColumnWidth(1.25),
                          2: pw.FlexColumnWidth(1.25),
                          3: pw.FlexColumnWidth(1.25),
                          4: pw.FlexColumnWidth(1),
                          5: pw.FlexColumnWidth(1),
                          6: pw.FlexColumnWidth(1.65),
                          7: pw.FlexColumnWidth(0.6),
                        },
                        children: [
                          pw.TableRow(
                            children: [
                              pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('No')),
                              pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Tanggal')),
                              pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Pilihan')),
                              pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Item')),
                              pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Nama')),
                              pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Kode')),
                              pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Harga')),
                              pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Program')),
                            ],
                          ),
                          ...filteredRecords.map((entry) {
                            final record = Map<String, dynamic>.from(entry.value);
                            return pw.TableRow(
                              children: [
                                pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text((filteredRecords.indexOf(entry) + 1).toString())),
                                pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text(record['date'] ?? '-')),
                                pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text(record['user'] ?? '-')),
                                pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text(record['name'] ?? '-')),
                                pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text(record['fullname'] ?? '-')),
                                pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text(record['sku'] ?? '-')),
                                pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text(formatRupiah(record['amount'] ?? '0'))),
                                pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text(record['program'] ?? '-')),
                              ],
                            );
                          }),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text('Jumlah Item: $totalItems', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Total Harga: ${formatRupiah(totalUang.toString())}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    ],
                  );
                },
              ),
            );

            // Print or Save PDF
            await Printing.layoutPdf(onLayout: (format) async => pdf.save());
          }
        }
      }
    }
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

  void _addOrUpdateRecord() {
    if (_formKey.currentState!.validate()) {
      final newRecord = {
        'date': _dateController.text,
        'user': _userType,
        'name': _nameController.text,
        'fullname': _fullnameController.text,
        'sku': _skuController.text,
        'amount': _amountController.text,
        'program': _programMethod,
      };

      if (_editingKey.isEmpty) {
        _database.child('records_price_update').push().set(newRecord).then((_) {
          _clearForm();
        });
      } else {
        _database.child('records_price_update').child(_editingKey).set(newRecord).then((_) {
          setState(() {
            _editingKey = '';
          });
          _clearForm();
        });
      }
    }
  }

  void _clearForm() {
    _userType = 'Customer';
    _nameController.clear();
    _fullnameController.clear();
    _skuController.clear();
    _amountController.clear();
    _dateController.clear();
    _programMethod = 'MI';
  }

  void _deleteRecord(String key) {
    _database.child('records_price_update').child(key).remove().then((_) {
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
    _editingKey = key;
    _userType= record['user'];
    _nameController.text = record['name'];
    _fullnameController.text = record['fullname'];
    _skuController.text = record['sku'];
    _amountController.text = record['amount'];
    _dateController.text = record['date'];
    _programMethod = record['program'];
  }

  // @override
  // void initState() {
  //   super.initState();
  //   _amountController.addListener(() {
  //     final formatted = formatRupiah(_amountController.text.replaceAll('.', ''));
  //     if (_amountController.text != formatted) {
  //       _amountController.value = _amountController.value.copyWith(
  //         text: formatted,
  //         selection: TextSelection.collapsed(offset: formatted.length),
  //       );
  //     }
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text('', style: TextStyle(fontSize: 16)),
            // Text('YAYASAN BUDI DHARMA KIRT', style: TextStyle(fontSize: 16)),
            // Text('Kelenteng Hok Heng Kiong Kota Tangerang', style: TextStyle(fontSize: 14)),
            // Text('WA 0838-0870-2766(Sukardi/Ang Tek Kang)', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.print),
            onPressed: () {
              generatePriceUpdateReport(context);
            },
          ),
        ],


      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('UPDATE HARGA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
              DropdownButtonFormField<String>(
                value: _userType,
                decoration: InputDecoration(labelText: 'Pilihan'),
                items: ['Customer','Suplier']
                    .map((method) => DropdownMenuItem(value: method, child: Text(method)))
                    .toList(),
                onChanged: (value) => setState(() => _userType = value!),
              ),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nama Item'),
                validator: (value) => value == null || value.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _fullnameController,
                decoration: InputDecoration(labelText: 'Nama'),
                validator: (value) => value == null || value.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _skuController,
                decoration: InputDecoration(labelText: 'Kode'),
                validator: (value) => value == null || value.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Harga (Rp)'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) => value == null || value.isEmpty ? 'Nominal tidak boleh kosong' : null,
              ),
              DropdownButtonFormField<String>(
                value: _programMethod,
                decoration: InputDecoration(labelText: 'Program'),
                items: ['MI','IMP', 'MA']
                    .map((method) => DropdownMenuItem(value: method, child: Text(method)))
                    .toList(),
                onChanged: (value) => setState(() => _programMethod = value!),
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _addOrUpdateRecord,
                child: Text(_editingKey.isEmpty ? 'Simpan' : 'Update'),
              ),
              SizedBox(height: 20.0),
              Center(
                child: Text('Daftar Update Harga', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              StreamBuilder(
                stream: _database.child('records_price_update').onValue,
                builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                    final records = Map<String, dynamic>.from(
                        snapshot.data!.snapshot.value as Map<dynamic, dynamic>
                    );
                    return ListView.builder(
                      shrinkWrap: true,
                      itemCount: records.keys.length,
                      itemBuilder: (context, index) {
                        final key = records.keys.elementAt(index);
                        final record = Map<String, dynamic>.from(records[key]);
                        return ListTile(
                          title: Text('${record['name']} - ${record['fullname']} - ${record['user']} - ${record['sku']}'),
                          subtitle: Text('${formatRupiah(record['amount'])} - ${record['date']} - ${record['program']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () => _editRecord(record, key),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _deleteRecord(key),
                              ),
                              IconButton(
                                icon: Icon(Icons.print),
                                onPressed: () => _generateTransactionPDF(record),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  } else {
                    return Center(child: Text('Belum ada data'));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}



