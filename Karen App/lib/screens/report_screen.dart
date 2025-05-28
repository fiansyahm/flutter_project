import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/transaction.dart';

class ReportScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isGoldTheme;

  const ReportScreen({super.key, required this.onThemeToggle, required this.isGoldTheme});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  DateTime selectedDate = DateTime.now();
  List<Transaction> transactions = [];
  String selectedTab = 'Analisis';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final allTransactions = await dbHelper.getTransactions();
    setState(() {
      transactions = allTransactions.where((t) {
        try {
          final transactionDate = DateTime.parse(t.date);
          return transactionDate.year == selectedDate.year &&
              transactionDate.month == selectedDate.month;
        } catch (e) {
          print('Error parsing date: ${t.date}');
          return false;
        }
      }).toList();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _loadTransactions();
      });
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des'
    ];
    return months[month - 1];
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    final income = transactions
        .where((t) => t.type == 'income')
        .fold(0, (sum, t) => sum + t.amount);
    final expense = transactions
        .where((t) => t.type == 'expense')
        .fold(0, (sum, t) => sum + t.amount);
    final balance = income - expense;

    final total = income + (expense > income ? expense : income);
    final expensePercentage = total > 0 ? (expense / total * 100).toStringAsFixed(1) : '0';
    final balanceValue = balance >= 0 ? balance.toDouble() : 0.0;
    final balancePercentage = total > 0 ? (balanceValue / total * 100).toStringAsFixed(1) : '0';

    final expenseChartValue = expense > 0 ? expense.toDouble() : 0.1;
    final balanceChartValue = balanceValue > 0 ? balanceValue : 0.1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implementasi pencarian
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).primaryColor,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedTab = 'Analisis'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: selectedTab == 'Analisis'
                          ? Colors.grey[800]
                          : Theme.of(context).primaryColor,
                      child: Center(
                        child: Text(
                          'Analisis',
                          style: TextStyle(
                            color: selectedTab == 'Analisis'
                                ? Colors.white
                                : Theme.of(context).textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedTab = 'Arus Kas'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: selectedTab == 'Arus Kas'
                          ? Colors.grey[800]
                          : Theme.of(context).primaryColor,
                      child: Center(
                        child: Text(
                          'Arus Kas',
                          style: TextStyle(
                            color: selectedTab == 'Arus Kas'
                                ? Colors.white
                                : Theme.of(context).textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: selectedTab == 'Analisis'
                ? SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_getMonthName(selectedDate.month)} ${selectedDate.year}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        Text(
                          'Saldo: Rp ${_formatNumber(balance)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green, // Static green for balance
                          ),
                        ),
                      ],
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Statistik Bulanan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pengeluaran:',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black
                                      )),
                                  Text(
                                    'Rp ${_formatNumber(expense)}',
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.red),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pemasukan:',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black
                                      )),
                                  Text(
                                    'Rp ${_formatNumber(income)}',
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.green), // Static green
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Anggaran Bulanan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tersisa: Rp ${_formatNumber(balance)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green, // Static green
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pemasukan: Rp ${_formatNumber(income)}',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.green), // Static green
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pengeluaran: Rp ${_formatNumber(expense)}',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Grafik Anggaran Bulanan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: SizedBox(
                              height: 150,
                              width: 150,
                              child: total == 0
                                  ? Center(
                                child: Text(
                                  'Tidak ada data',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color),
                                  textAlign: TextAlign.center,
                                ),
                              )
                                  : PieChart(
                                PieChartData(
                                  sections: [
                                    PieChartSectionData(
                                      value: expenseChartValue,
                                      color: Colors.red,
                                      title: '$expensePercentage%',
                                      radius: 60,
                                      titleStyle: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    PieChartSectionData(
                                      value: balanceChartValue,
                                      color: Colors.green, // Static green
                                      title: '$balancePercentage%',
                                      radius: 60,
                                      titleStyle: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadTransactions,
              child: transactions.isEmpty
                  ? Center(
                child: Text(
                  'Tidak ada transaksi untuk bulan ini',
                  style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color),
                ),
              )
                  : ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  DateTime transactionDate;
                  try {
                    transactionDate = DateTime.parse(transaction.date);
                  } catch (e) {
                    transactionDate = DateTime.now();
                    print('Error parsing date: ${transaction.date}');
                  }
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: transaction.type == 'income'
                          ? Colors.green
                          : transaction.type == 'expense'
                          ? Colors.red
                          : Colors.blue,
                      child: Icon(
                        transaction.type == 'income'
                            ? Icons.arrow_downward
                            : transaction.type == 'expense'
                            ? Icons.arrow_upward
                            : Icons.swap_horiz,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      transaction.title,
                      style: TextStyle(
                          color: Theme.of(context).textTheme.bodyLarge?.color),
                    ),
                    subtitle: Text(
                      '${transactionDate.day} ${_getMonthName(transactionDate.month)} - ${transaction.category}',
                      style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                    trailing: Text(
                      'Rp ${_formatNumber(transaction.amount)}',
                      style: TextStyle(
                        color: transaction.type == 'income'
                            ? Colors.green
                            : transaction.type == 'expense'
                            ? Colors.red
                            : Colors.blue,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}