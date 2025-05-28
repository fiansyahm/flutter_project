import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/transaction.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

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
            colorScheme: const ColorScheme.light(
              primary: Colors.black,
              onPrimary: Colors.white,
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

    // Calculate values for the donut chart
    final total = income + (expense > income ? expense : income);
    final expensePercentage = total > 0 ? (expense / total * 100).toStringAsFixed(1) : '0';
    final balanceValue = balance >= 0 ? balance.toDouble() : 0.0;
    final balancePercentage = total > 0 ? (balanceValue / total * 100).toStringAsFixed(1) : '0';

    // Ensure non-zero values to prevent chart rendering issues
    final expenseChartValue = expense > 0 ? expense.toDouble() : 0.1;
    final balanceChartValue = balanceValue > 0 ? balanceValue : 0.1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
        backgroundColor: Colors.yellow[700],
        foregroundColor: Colors.black,
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
          // Tabs
          Container(
            color: Colors.yellow[700],
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => selectedTab = 'Analisis'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      color: selectedTab == 'Analisis' ? Colors.black : Colors.yellow[700],
                      child: Center(
                        child: Text(
                          'Analisis',
                          style: TextStyle(
                            color: selectedTab == 'Analisis' ? Colors.white : Colors.black,
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
                      color: selectedTab == 'Arus Kas' ? Colors.black : Colors.yellow[700],
                      child: Center(
                        child: Text(
                          'Arus Kas',
                          style: TextStyle(
                            color: selectedTab == 'Arus Kas' ? Colors.white : Colors.black,
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
          // Content based on selected tab
          Expanded(
            child: selectedTab == 'Analisis'
                ? SingleChildScrollView(
              child: Column(
                children: [
                  // Monthly Statistics
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_getMonthName(selectedDate.month)} ${selectedDate.year}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Saldo: Rp ${_formatNumber(balance)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: balance >= 0 ? Colors.green : Colors.red,
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
                          const Text(
                            'Statistik Bulanan',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Pengeluaran:',
                                      style: TextStyle(fontSize: 14)),
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
                                  const Text('Pemasukan:',
                                      style: TextStyle(fontSize: 14)),
                                  Text(
                                    'Rp ${_formatNumber(income)}',
                                    style: const TextStyle(
                                        fontSize: 14, color: Colors.green),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Monthly Budget (Anggaran Bulanan) - Text Only
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Anggaran Bulanan',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tersisa: Rp ${_formatNumber(balance)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: balance >= 0 ? Colors.green : Colors.red,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pemasukan: Rp ${_formatNumber(income)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pengeluaran: Rp ${_formatNumber(expense)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Donut Chart - New Section
                  Card(
                    margin: const EdgeInsets.all(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Grafik Anggaran Bulanan',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: SizedBox(
                              height: 150,
                              width: 150,
                              child: total == 0
                                  ? const Center(
                                child: Text(
                                  'Tidak ada data',
                                  style: TextStyle(fontSize: 12),
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
                                      color: Colors.green,
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
                  ? const Center(
                child: Text(
                  'Tidak ada transaksi untuk bulan ini',
                  style: TextStyle(fontSize: 16),
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
                    title: Text(transaction.title),
                    subtitle: Text(
                      '${transactionDate.day} ${_getMonthName(transactionDate.month)} - ${transaction.category}',
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