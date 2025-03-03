import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'firebase_options.dart';


class IncomeApp extends StatefulWidget {
  @override
  _IncomeAppState createState() => _IncomeAppState();
}

class _IncomeAppState extends State<IncomeApp> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _dateController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _editingKey = '';
  String _searchQuery = '';
  List<String> _memberList = [];
  String? _selectedMember;
  final TextEditingController _textController = TextEditingController();

  // Fungsi untuk memformat angka menjadi format Rupiah
  String formatRupiah(String amount) {
    if (amount.isEmpty) return "Rp 0";
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(int.tryParse(amount.replaceAll('.', '')) ?? 0);
  }

  @override
  void initState() {
    super.initState();
    _fetchMembers();

    // Menambahkan pemformatan untuk amountController
    _priceController.addListener(() {
      final text = _priceController.text;
      final formatted = _formatCurrency(text.replaceAll('.', ''));
      if (_priceController.text != formatted) {
        _priceController.value = _priceController.value.copyWith(
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
            pw.Text('Jasa Angkut Sampah', style: pw.TextStyle(fontSize: 12)),
            pw.Text('Boging Trans', style: pw.TextStyle(fontSize: 10)),
            pw.Text('WA 0857-4074-0309', style: pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 10),
            pw.Text('Tanggal Mulai Pembayaran: ${record['date']}', style: pw.TextStyle(fontSize: 10)),
            pw.Text('Tanggal Terakhir Pembayaran: ${record['date2']}', style: pw.TextStyle(fontSize: 10)),
            pw.Text('Nama: ${record['name']}', style: pw.TextStyle(fontSize: 10)),
            pw.Text('Alamat: ${record['region']}', style: pw.TextStyle(fontSize: 10)),
            pw.Text('Iuran Bulanan: ${formatRupiah(record['price'])}', style: pw.TextStyle(fontSize: 10)),
            pw.Text('Total Iuran Hingga Saat ini: ${formatRupiah(record['amount'])}', style: pw.TextStyle(fontSize: 10)),
            pw.Text('Keterangan: ${record['description']}', style: pw.TextStyle(fontSize: 10)),
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
        'name': _selectedMember,
        'price': _priceController.text,
        'description': _descriptionController.text,
      };

      if (_editingKey.isEmpty) {
        _database.child('records_tagihan').push().set(newRecord).then((_) {
          _clearForm();
        });
      } else {
        _database.child('records_tagihan').child(_editingKey).set(newRecord).then((_) {
          setState(() {
            _editingKey = '';
          });
          _clearForm();
        });
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _priceController.clear();
    _dateController.clear();
    _descriptionController.clear();
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
    _editingKey = key;
    setState(() {
      _memberList = _memberList.where((name) => name == record['name']).toList();
    });
    _priceController.text = record['price'];
    _dateController.text = record['date'];
    _descriptionController.text=record['description'];
  }

  Future<void> _fetchMembers() async {
    try {
      final snapshot = await _database.child('records_Member').get();
      if (snapshot.exists) {
        final Map<dynamic, dynamic>? members = snapshot.value as Map<dynamic, dynamic>?;
        if (members != null) {
          setState(() {
            _memberList = members.values.map((e) => e['name'].toString()).toList();
          });
        }
      }
    } catch (e) {
      print('Error fetching members: $e');
    }
  }

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
            onPressed: () async {
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

                // Fetch data dari Firebase
                final snapshot = await _database.child('records_tagihan').get();
                if (snapshot.exists) {
                  final allRecords = Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
                  final filteredRecords = allRecords.entries.where((entry) {
                    final recordDate = DateFormat('dd-MM-yyyy').parse(entry.value['date']);
                    return recordDate.isAfter(startDate.subtract(Duration(days: 1))) &&
                        recordDate.isBefore(endDate.add(Duration(days: 1)));
                  }).toList();

                  if (filteredRecords.isNotEmpty) {
                    final pdf = pw.Document();

                    // Hitung total donatur dan total uang
                    int totalDonatur = filteredRecords.length;
                    final totalUang = filteredRecords.fold(0, (sum, entry) {
                      final record = Map<String, dynamic>.from(entry.value);
                      // Ambil nilai nominal dari record dan konversi menjadi integer
                      final amount = int.tryParse(record['amount'].replaceAll('.', '')) ?? 0;
                      return sum + amount;
                    });

                    pdf.addPage(
                      pw.Page(
                        build: (pw.Context context) {
                          return pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Laporan Iuran', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                              pw.Text('Periode: ${DateFormat('dd-MM-yyyy').format(startDate)} - ${DateFormat('dd-MM-yyyy').format(endDate)}'),
                              pw.SizedBox(height: 10),
                              pw.Table(
                                border: pw.TableBorder.all(),
                                columnWidths: {
                                  0: pw.FlexColumnWidth(0.5), //Nama
                                  1: pw.FlexColumnWidth(1), // Alamat
                                  2: pw.FlexColumnWidth(1),  // Iuran
                                  3: pw.FlexColumnWidth(1), // Tanggal
                                  4: pw.FlexColumnWidth(1.5), // Keterangan
                                },
                                children: [
                                  pw.TableRow(
                                    children: [
                                      pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('No')),
                                      pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Nama')),
                                      pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Alamat')),
                                      pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Total Iuran')),
                                      pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Tanggal')),
                                      pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Keterangan')),
                                    ],
                                  ),
                                  ...filteredRecords.map((entry) {
                                    final record = Map<String, dynamic>.from(entry.value);
                                    return pw.TableRow(
                                      children: [
                                        pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text((filteredRecords.indexOf(entry) + 1).toString())), // No Urut
                                        pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text(record['name'] ?? '-')),
                                        pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text(record['region'] ?? '-')),
                                        pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text(formatRupiah(record['amount'] ?? '0'))),
                                        pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text(record['date'] ?? '-')),
                                        pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text(record['description'] ?? '-')),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                              pw.SizedBox(height: 10),
                              pw.Text('Jumlah Transaksi: $totalDonatur', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                              pw.Text('Total Iuran: ${formatRupiah(totalUang.toString())}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
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
              Text('Form Iuran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                value: _selectedMember,
                decoration: InputDecoration(labelText: 'Pilih Nama'),
                items: _memberList.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedMember = newValue;
                    _textController.text = newValue ?? '';
                  });
                },
                validator: (value) =>
                value == null || value.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _priceController,
                decoration: InputDecoration(labelText: 'Iuran Bulanan (Rp)'),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) => value == null || value.isEmpty ? 'Nominal tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Keterangan'),
                validator: (value) {
                  // Tidak ada pesan kesalahan, menganggap string kosong valid
                  return null;
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _addOrUpdateRecord,
                child: Text(_editingKey.isEmpty ? 'Simpan' : 'Update'),
              ),
              SizedBox(height: 20.0),
              Center(
                child: Text('Daftar Iuran', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              SizedBox(height: 10),
              TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Cari berdasarkan nama',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              SizedBox(height: 10),
              // Tambahkan Container untuk memberikan batasan tinggi
              Container(
                height: 400, // Berikan tinggi tetap atau sesuai kebutuhan
                child: StreamBuilder(
                  stream: _database.child('records_tagihan').onValue,
                  builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                      final records = Map<String, dynamic>.from(
                          snapshot.data!.snapshot.value as Map<dynamic, dynamic>);

                      // Filter berdasarkan nama
                      final filteredRecords = records.entries
                          .where((entry) => entry.value['name']
                          .toString()
                          .toLowerCase()
                          .contains(_searchQuery))
                          .toList();

                      if (filteredRecords.isEmpty) {
                        return Center(child: Text('Tidak ada hasil yang sesuai'));
                      }

                      return ListView.builder(
                        itemCount: filteredRecords.length,
                        itemBuilder: (context, index) {
                          final key = filteredRecords[index].key;
                          final record = Map<String, dynamic>.from(filteredRecords[index].value);

                          return ListTile(
                            title: Text(' ${record['name']}        -        ${record['description']}  '),
                            subtitle: Text(' ${record['date']}      -     ${formatRupiah(record['price'])}'),
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
              ),
            ],
          ),
        ),
      ),

    );
  }
}



