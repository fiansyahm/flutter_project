// screens/sales_recap_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db/database_helper.dart';
import '../models/purchase_transaction.dart';

class SalesRecapScreen extends StatefulWidget {
  const SalesRecapScreen({super.key});

  @override
  State<SalesRecapScreen> createState() => _SalesRecapScreenState();
}

class _SalesRecapScreenState extends State<SalesRecapScreen> {
  List<PurchaseTransaction> _transactions = [];
  final dbHelper = DatabaseHelper.instance;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() async {
    final data = await dbHelper.getTransactions();
    setState(() {
      _transactions = data;
    });
  }

  // Calculate daily stats: gross revenue (omset) and profit
  Map<String, int> _calculateDailyStats() {
    int grossRevenue = 0;
    int profit = 0;

    // Filter transactions for the selected date
    final filteredTransactions = _transactions.where((transaction) {
      return transaction.date.year == _selectedDate.year &&
          transaction.date.month == _selectedDate.month &&
          transaction.date.day == _selectedDate.day;
    }).toList();

    // Calculate gross revenue and profit
    for (var transaction in filteredTransactions) {
      final items = jsonDecode(transaction.items) as List;
      grossRevenue += transaction.total; // Total sales (selling price)
      for (var item in items) {
        final quantity = item['quantity'] as int;
        final sellingPrice = item['price'] as int;
        final purchasePrice = item['purchasePrice'] as int; // Assumes purchasePrice is stored
        profit += (sellingPrice - purchasePrice) * quantity;
      }
    }

    return {
      'grossRevenue': grossRevenue,
      'profit': profit,
    };
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Pilih Tanggal',
      fieldLabelText: 'Tanggal',
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // Prepare data for the donut chart (PieChart)
  List<PieChartSectionData> _getPieChartData(int grossRevenue, int profit) {
    final filteredTransactions = _transactions.where((transaction) {
      return transaction.date.year == _selectedDate.year &&
          transaction.date.month == _selectedDate.month &&
          transaction.date.day == _selectedDate.day;
    }).toList();

    if (filteredTransactions.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          title: 'Tidak ada data',
          color: Colors.grey,
          radius: 50,
          titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
        ),
      ];
    }

    // Ensure profit doesn't exceed grossRevenue for chart purposes
    double adjustedProfit = profit.toDouble();
    if (adjustedProfit < 0) adjustedProfit = 0; // Avoid negative values in the chart
    if (adjustedProfit > grossRevenue) adjustedProfit = grossRevenue.toDouble();

    // Calculate the remaining omset (grossRevenue - profit)
    final remainingOmset = grossRevenue - adjustedProfit;

    return [
      PieChartSectionData(
        value: remainingOmset > 0 ? remainingOmset : 1, // Avoid zero value for chart rendering
        title: 'Omset\nRp ${_formatNumber(grossRevenue)}',
        color: Colors.red,
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
      ),
      PieChartSectionData(
        value: adjustedProfit > 0 ? adjustedProfit : 1, // Avoid zero value for chart rendering
        title: 'Keuntungan\nRp ${_formatNumber(profit)}',
        color: Colors.green,
        radius: 50,
        titleStyle: const TextStyle(fontSize: 12, color: Colors.white),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateDailyStats();
    final grossRevenue = stats['grossRevenue'] ?? 0;
    final profit = stats['profit'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Penjualan'),
        backgroundColor: Colors.yellow[700],
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tanggal: ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sections: _getPieChartData(grossRevenue, profit),
                              centerSpaceRadius: 40, // Makes it a donut chart
                              sectionsSpace: 2,
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Omset',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Rp ${_formatNumber(grossRevenue)}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pendapatan Kotor (Omset)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Rp ${_formatNumber(grossRevenue)}',
                      style: const TextStyle(fontSize: 16, color: Colors.green),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Keuntungan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Rp ${_formatNumber(profit)}',
                      style: TextStyle(
                        fontSize: 16,
                        color: profit >= 0 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}