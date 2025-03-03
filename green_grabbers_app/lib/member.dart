import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'firebase_options.dart';


class MemberApp extends StatefulWidget {
  @override
  _MemberAppState createState() => _MemberAppState();
}

class _MemberAppState extends State<MemberApp> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  String _editingKey = '';
  String _searchQuery = '';

  // Fungsi untuk memformat angka menjadi format Rupiah
  String formatRupiah(String amount) {
    if (amount.isEmpty) return "Rp 0";
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(int.tryParse(amount.replaceAll('.', '')) ?? 0);
  }

  @override
  void initState() {
    super.initState();

  }

  Future<String> _calculateTotalAmount(String name) async {
    int total = 0;
    final snapshot = await _database.child('records_income').get();

    if (snapshot.exists && snapshot.value != null) {
      // Casting nilai dari snapshot menjadi Map
      final Map<dynamic, dynamic> records = Map<dynamic, dynamic>.from(snapshot.value as Map);

      records.forEach((key, value) {
        // Casting setiap item dalam records
        final record = Map<String, dynamic>.from(value as Map);

        // Periksa apakah 'name' cocok dan pastikan 'amount' ada
        if (record['name'] == name && record['amount'] != null) {
          final amount = int.tryParse(record['amount'].replaceAll('.', '')) ?? 0;
          total=total+amount;
        }
      });
    }

    return total.toString();
  }

  // Fungsi untuk memformat input dengan titik setiap 3 angka
  String _formatCurrency(String text) {
    // final amount = int.tryParse(text) ?? 0;
    // final formatted = NumberFormat('#,###').format(amount);  // Menambahkan pemisah ribuan
    // return formatted;
    return text;
  }

  Future<void> _generateTransactionPDF(Map<String, dynamic> record,String total) async {
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
            pw.Text('Nama: ${record['name']}', style: pw.TextStyle(fontSize: 10)),
            pw.Text('Alamat: ${record['address']}', style: pw.TextStyle(fontSize: 10)),
            pw.Text('Total Pembayaran: ${formatRupiah(total)}', style: pw.TextStyle(fontSize: 10)),
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

  void _addOrUpdateRecord() {
    if (_formKey.currentState!.validate()) {

      final newRecord = {
        'name': _nameController.text,
        'address': _addressController.text,
      };

      if (_editingKey.isEmpty) {
        _database.child('records_Member').push().set(newRecord).then((_) {
          _clearForm();
        });
      } else {
        _database.child('records_Member').child(_editingKey).set(newRecord).then((_) {
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
    _addressController.clear();
  }

  void _deleteRecord(String key) {
    _database.child('records_Member').child(key).remove().then((_) {
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
    _nameController.text = record['name'];
    _addressController.text=record['address'];
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
                final snapshot = await _database.child('records_Member').get();
                if (snapshot.exists) {
                  final allRecords = Map<String, dynamic>.from(snapshot.value as Map<dynamic, dynamic>);
                  final filteredRecords = allRecords.entries.toList();

                  if (filteredRecords.isNotEmpty) {
                    final pdf = pw.Document();

                    // Hitung total donatur dan total uang
                    int totalDonatur = filteredRecords.length;
                    int totalUang = 0;

                    final snapshot2 = await _database.child('records_tagihan').get();
                    if (snapshot2.exists) {
                      final allRecords2 = Map<String, dynamic>.from(snapshot2.value as Map<dynamic, dynamic>);
                      final filteredRecords2 = allRecords2.entries.where((entry) {
                        final recordDate = DateFormat('dd-MM-yyyy').parse(entry.value['date']);
                        return recordDate.isAfter(startDate.subtract(Duration(days: 1))) &&
                            recordDate.isBefore(endDate.add(Duration(days: 1)));
                      }).toList();
                      final totalUang2 = filteredRecords2.fold(0, (sum2, entry2) {
                        final record2 = Map<String, dynamic>.from(entry2.value);
                        // Ambil nilai nominal dari record dan konversi menjadi integer
                        final amount2 = int.tryParse(record2['amount'].replaceAll('.', '')) ?? 0;
                        return sum2 + amount2;
                      });
                      totalUang=totalUang2;
                      print(totalUang2);
                    }

                    pdf.addPage(
                      pw.Page(
                        build: (pw.Context context) {
                          return pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Laporan Pemasukan', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                              pw.Text('Periode: ${DateFormat('dd-MM-yyyy').format(startDate)} - ${DateFormat('dd-MM-yyyy').format(endDate)}'),
                              pw.SizedBox(height: 10),
                              pw.Table(
                                border: pw.TableBorder.all(),
                                columnWidths: {
                                  0: pw.FlexColumnWidth(0.5), //Nama
                                  1: pw.FlexColumnWidth(1.5), // Alamat
                                  2: pw.FlexColumnWidth(1.5), // Total
                                },
                                children: [
                                  pw.TableRow(
                                    children: [
                                      pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('No')),
                                      pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Nama')),
                                      pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Alamat')),
                                      pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Total')),
                                    ],
                                  ),
                                  ...filteredRecords.map((entry) {
                                    final record = Map<String, dynamic>.from(entry.value);

                                    final allRecordsUser = Map<String, dynamic>.from(snapshot2.value as Map<dynamic, dynamic>);
                                    final filteredRecordsUser = allRecordsUser.entries.where((entry) {
                                      final recordDate = DateFormat('dd-MM-yyyy').parse(entry.value['date']);
                                      return recordDate.isAfter(startDate.subtract(Duration(days: 1))) &&
                                          recordDate.isBefore(endDate.add(Duration(days: 1)));
                                    }).toList();
                                    final totalUangUser = filteredRecordsUser.fold(0, (sum2, entry2) {
                                      final record2 = Map<String, dynamic>.from(entry2.value);

                                      // Ambil nilai nominal dari record dan konversi menjadi integer
                                      if(record['name']==record2['name']){
                                        final amount2 = int.tryParse(record2['amount'].replaceAll('.', '')) ?? 0;
                                        return sum2 + amount2;
                                      }
                                      else{
                                        return sum2;
                                      }

                                    });
                                    return pw.TableRow(
                                      children: [
                                        pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text((filteredRecords.indexOf(entry) + 1).toString())), // No Urut
                                        pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text(record['name'] ?? '-')),
                                        pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text(record['address'] ?? '-')),
                                        pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text(totalUangUser.toString() ?? '-')),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                              pw.SizedBox(height: 10),
                              pw.Text('Jumlah Pelanggan: $totalDonatur', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                              pw.Text('Total Pemasukan: ${formatRupiah(totalUang.toString())}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
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
              Text('Form User', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nama'),
                validator: (value) => value == null || value.isEmpty ? 'Nama tidak boleh kosong' : null,
              ),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(labelText: 'Alamat'),
                validator: (value) => value == null || value.isEmpty ? 'Alamat tidak boleh kosong' : null,
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _addOrUpdateRecord,
                child: Text(_editingKey.isEmpty ? 'Simpan' : 'Update'),
              ),
              SizedBox(height: 20.0),
              Center(
                child: Text('Daftar User', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                  stream: _database.child('records_Member').onValue,
                  builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                      final records = Map<String, dynamic>.from(
                          snapshot.data!.snapshot.value as Map<dynamic, dynamic>);

                      // Filter berdasarkan nama
                      final filteredRecords = records.entries
                          .where((entry) {
                        final name = entry.value['name']?.toString().toLowerCase() ?? '';
                        final address = entry.value['address']?.toString().toLowerCase() ?? '';
                        return name.contains(_searchQuery.toLowerCase()) ||
                            address.contains(_searchQuery.toLowerCase());
                      }).toList();

                      if (filteredRecords.isEmpty) {
                        return Center(child: Text('Tidak ada hasil yang sesuai'));
                      }

                      return ListView.builder(
                        itemCount: filteredRecords.length,
                        itemBuilder: (context, index) {
                          final key = filteredRecords[index].key;
                          final record = Map<String, dynamic>.from(filteredRecords[index].value);
                          print(record);

                          return FutureBuilder<String>(
                            future: _calculateTotalAmount(record['name']),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return ListTile(
                                  title: Text('${record['name']} - ${record['address']}'),
                                  subtitle: Text('Menghitung total...'),
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
                                        onPressed: () => _generateTransactionPDF(record,'0'),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              if (snapshot.hasError) {
                                return ListTile(
                                  title: Text('${record['name']} - ${record['address']}'),
                                  subtitle: Text('Gagal menghitung total'),
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
                                        onPressed: () => _generateTransactionPDF(record,'0'),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              // Menggunakan snapshot.data yang sudah diformat dalam format string
                              final totalAmount = snapshot.data ?? 'Rp 0'; // Default 'Rp 0' jika null
                              return ListTile(
                                title: Text('${record['name']} - ${record['address']}'),
                                subtitle: Text(
                                  'Total: $totalAmount',
                                ),
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
                                      onPressed: () => _generateTransactionPDF(record,totalAmount),
                                    ),
                                  ],
                                ),
                              );
                            },
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



