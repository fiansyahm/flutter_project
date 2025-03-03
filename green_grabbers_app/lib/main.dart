import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'income.dart';  // Import the income page
import 'outcome.dart'; // Import the outcome page
import 'member.dart'; // Import the outcome page
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:pdf/widgets.dart' as pw;

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
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Fungsi untuk memformat angka menjadi format Rupiah
  String formatRupiah(String amount) {
    if (amount.isEmpty) return "Rp 0";
    final formatter = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(int.tryParse(amount.replaceAll('.', '')) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Boging Trans Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navigating to Income Page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => IncomeApp()),
                );
              },
              child: Text('Pemasukan'),
            ),
            SizedBox(height: 20),  // Spacer between buttons
            ElevatedButton(
              onPressed: () {
                // Navigating to Outcome Page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => OutcomeApp()),
                );
              },
              child: Text('Pengeluaran'),
            ),
            SizedBox(height: 20),  // Spacer between buttons
            ElevatedButton(
              onPressed: () {
                // Navigating to Outcome Page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MemberApp()),
                );
              },
              child: Text('User'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
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
                  final snapshotOutcome = await _database.child('records_outcome').get();
                  final snapshotIncome = await _database.child('records_income').get();

                  Map<String, double> dailyBalance = {};
                  if (snapshotOutcome.exists && snapshotIncome.exists) {
                    // Parsing outcome data
                    final outcomeData = Map<String, dynamic>.from(snapshotOutcome.value as Map);
                    for (var key in outcomeData.keys) {
                      final record = outcomeData[key];
                      final recordDate = DateFormat('dd-MM-yyyy').parse(record['date']);
                      final amount = double.parse(record['amount']);
                      print(amount);
                      if (recordDate.isAfter(startDate.subtract(Duration(days: 1))) && recordDate.isBefore(endDate.add(Duration(days: 1)))) {
                        dailyBalance[recordDate.toString()] = (dailyBalance[recordDate.toString()] ?? 0) - amount;
                      }
                    }

                    // Parsing income data
                    final incomeData = Map<String, dynamic>.from(snapshotIncome.value as Map);
                    for (var key in incomeData.keys) {
                      final record = incomeData[key];
                      final recordDate = DateFormat('dd-MM-yyyy').parse(record['date']);
                      final amount = double.parse(record['amount']);
                      print(amount);
                      if (recordDate.isAfter(startDate.subtract(Duration(days: 1))) && recordDate.isBefore(endDate.add(Duration(days: 1)))) {
                        dailyBalance[recordDate.toString()] = (dailyBalance[recordDate.toString()] ?? 0) + amount;
                      }
                    }
                  }

                  // Mengurutkan saldo berdasarkan tanggal
                  final sortedDates = dailyBalance.keys.toList()..sort();
                  double cumulativeBalance = 0;

                  final pdf = pw.Document();
                  pdf.addPage(
                    pw.Page(
                      build: (pw.Context context) {
                        return pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Laporan Neraca Pembukuan', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                            pw.Text('Periode: ${DateFormat('dd-MM-yyyy').format(startDate)} - ${DateFormat('dd-MM-yyyy').format(endDate)}'),
                            pw.SizedBox(height: 10),
                            pw.Table(
                              border: pw.TableBorder.all(),
                              columnWidths: {
                                0: pw.FlexColumnWidth(1), //No
                                1: pw.FlexColumnWidth(2), //Debit & Kredit
                                2: pw.FlexColumnWidth(2),  // Saldo Akhir
                              },
                              children: [
                                pw.TableRow(
                                  children: [
                                    pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('No')),
                                    pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Total Debit & Kredit')),
                                    pw.Padding(padding: pw.EdgeInsets.all(4), child: pw.Text('Saldo Akhir')),
                                  ],
                                ),

                                ...sortedDates.map((date) {
                                  cumulativeBalance += dailyBalance[date]!;
                                  return pw.TableRow(
                                    children: [
                                      pw.Padding(
                                        padding: pw.EdgeInsets.all(4),
                                        child: pw.Text("${date.split(' ')[0]}"),
                                      ),
                                      pw.Padding(
                                        padding: pw.EdgeInsets.all(4),
                                        child: pw.Text(dailyBalance[date]!.toString()), // Cast ke string dengan 2 desimal
                                      ),
                                      pw.Padding(
                                        padding: pw.EdgeInsets.all(4),
                                        child: pw.Text('${formatRupiah(cumulativeBalance.toString())}'), // Cast ke string dengan 2 desimal
                                      ),
                                    ],
                                  );
                                }),

                              ],
                            ),
                            pw.SizedBox(height: 10),
                            pw.Text('Saldo Akhir: ${formatRupiah(cumulativeBalance.toString())}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          ],
                        );
                      },
                    ),
                  );

                  await Printing.layoutPdf(onLayout: (format) async => pdf.save());

                  // final report = sortedDates.map((date) {
                  //   cumulativeBalance += dailyBalance[date]!;
                  //   return "${date.split(' ')[0]}: \nSaldo Harian ${dailyBalance[date]!} \nSaldo Akhir $cumulativeBalance \n\n";
                  // }).join('\n');

                  // Tampilkan laporan
                  // showDialog(
                  //   context: context,
                  //   builder: (context) {
                  //     return AlertDialog(
                  //       title: Text('Neraca Pembukuan'),
                  //       content: Text(report),
                  //       actions: [
                  //         TextButton(
                  //           onPressed: () => Navigator.of(context).pop(),
                  //           child: Text('Tutup'),
                  //         ),
                  //       ],
                  //     );
                  //   },
                  // );
                }
              },
              child: Text('Neraca Pembukuan'),
            ),
          ],
        ),
      ),
    );
  }
}
