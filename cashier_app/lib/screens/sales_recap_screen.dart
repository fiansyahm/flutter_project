import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../db/database_helper.dart';
import '../db/adapters.dart';

class SalesRecapScreen extends StatefulWidget {
  const SalesRecapScreen({super.key});

  @override
  State<SalesRecapScreen> createState() => _SalesRecapScreenState();
}

class _SalesRecapScreenState extends State<SalesRecapScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<PurchaseTransaction> _transactions = [];
  final dbHelper = DatabaseHelper.instance;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7)); // Default to last 7 days
  DateTime _endDate = DateTime.now();
  String? _storeName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTransactions();
    _loadStoreProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadTransactions() async {
    final data = await dbHelper.getTransactions();
    setState(() {
      _transactions = data;
    });
  }

  void _loadStoreProfile() async {
    final profile = await dbHelper.getStoreProfile();
    setState(() {
      _storeName = profile?.storeName ?? 'Aplikasi Kasir';
    });
  }

  void _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      helpText: 'Pilih Rentang Tanggal',
      fieldStartLabelText: 'Tanggal Mulai',
      fieldEndLabelText: 'Tanggal Selesai',
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Map<String, int> _calculateDailyStats() {
    int grossRevenue = 0;
    int profit = 0;

    final filteredTransactions = _transactions.where((transaction) {
      return transaction.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          transaction.date.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    for (var transaction in filteredTransactions) {
      final items = jsonDecode(transaction.items) as List;
      grossRevenue += transaction.total;
      for (var item in items) {
        final quantity = item['quantity'] as int;
        final sellingPrice = item['price'] as int;
        final purchasePrice = item['purchasePrice'] as int;
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

  List<PieChartSectionData> _getPieChartData(int grossRevenue, int profit) {
    final filteredTransactions = _transactions.where((transaction) {
      return transaction.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          transaction.date.isBefore(_endDate.add(const Duration(days: 1)));
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

    double adjustedProfit = profit.toDouble();
    if (adjustedProfit < 0) adjustedProfit = 0;
    if (adjustedProfit > grossRevenue) adjustedProfit = grossRevenue.toDouble();

    final remainingOmset = grossRevenue - adjustedProfit;

    return [
      PieChartSectionData(
        value: remainingOmset > 0 ? remainingOmset.toDouble() : 1,
        title: 'Omset\nRp ${_formatNumber(grossRevenue)}',
        color: Colors.red,
        radius: 100,
        titleStyle: const TextStyle(fontSize: 16, color: Colors.white),
      ),
      PieChartSectionData(
        value: adjustedProfit > 0 ? adjustedProfit : 1,
        title: 'Keuntungan\nRp ${_formatNumber(profit)}',
        color: Colors.green,
        radius: 100,
        titleStyle: const TextStyle(fontSize: 16, color: Colors.white),
      ),
    ];
  }

  List<Map<String, dynamic>> _getSoldItems() {
    final soldItems = <Map<String, dynamic>>[];
    final filteredTransactions = _transactions.where((transaction) {
      return transaction.date.isAfter(_startDate.subtract(const Duration(days: 1))) &&
          transaction.date.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    for (var transaction in filteredTransactions) {
      final items = jsonDecode(transaction.items) as List;
      for (var item in items) {
        final name = item['name'] as String;
        final quantity = item['quantity'] as int;
        final price = item['price'] as int;
        final purchasePrice = item['purchasePrice'] as int;
        final total = quantity * price;
        final profit = (price - purchasePrice) * quantity;
        soldItems.add({
          'name': name,
          'quantity': quantity,
          'price': price,
          'total': total,
          'profit': profit,
          'cashier': transaction.cashier,
          'storeName': _storeName,
        });
      }
    }

    return soldItems;
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateDailyStats();
    final grossRevenue = stats['grossRevenue'] ?? 0;
    final profit = stats['profit'] ?? 0;
    final soldItems = _getSoldItems();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekap Penjualan'),
        backgroundColor: Colors.yellow[700],
        foregroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tanggal: ${DateFormat('dd MMM yyyy').format(_startDate)} - ${DateFormat('dd MMM yyyy').format(_endDate)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.calendar_today),
                  onPressed: () => _selectDateRange(context),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Grafik Penjualan'),
              Tab(text: 'Daftar Penjualan'),
            ],
            labelColor: Colors.black,
            indicatorColor: Colors.black,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Grafik Penjualan Tab
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 200,
                            child: PieChart(
                              PieChartData(
                                sections: _getPieChartData(grossRevenue, profit),
                                centerSpaceRadius: 40,
                                sectionsSpace: 2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Pendapatan Kotor (Omset)\nRp ${_formatNumber(grossRevenue)}'),
                                ],
                              ),
                              const SizedBox(width: 32),
                              Row(
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    color: Colors.green,
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Keuntungan\nRp ${_formatNumber(profit)}'),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Daftar Penjualan Tab
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 4,
                    child: soldItems.isEmpty
                        ? const Center(child: Text('Tidak ada penjualan pada rentang tanggal ini'))
                        : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: soldItems.length,
                      itemBuilder: (ctx, i) {
                        final item = soldItems[i];
                        return ListTile(
                          title: Text(item['name']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Jumlah: ${item['quantity']} x Rp ${_formatNumber(item['price'])}'),
                              Text('Keuntungan: Rp ${_formatNumber(item['profit'])}'),
                              Text('Kasir: ${item['cashier']}'),
                              Text('Toko: ${item['storeName']}'),
                            ],
                          ),
                          trailing: Text('Total: Rp ${_formatNumber(item['total'])}'),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}