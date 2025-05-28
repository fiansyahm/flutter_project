// screens/home_page.dart
import 'package:flutter/material.dart';
import 'calendar_screen.dart';
import 'report_screen.dart';
import '../db/database_helper.dart';
import '../models/transaction.dart';
import '../widgets/custom_bottom_bar.dart';
import '../widgets/transaction_form.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Transaction> _transactions = [];
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final dbHelper = DatabaseHelper();
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _refreshTransactions();
  }

  void _refreshTransactions() async {
    final data = await dbHelper.getTransactions();
    setState(() {
      _transactions = data
          .where((t) =>
      t.date.year == selectedDate.year &&
          t.date.month == selectedDate.month)
          .toList();
    });
  }

  Future<void> _selectMonth(BuildContext context) async {
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
        _refreshTransactions();
      });
    }
  }

  void _showForm({Transaction? transaction}) {
    if (transaction != null) {
      _titleController.text = transaction.title;
      _amountController.text = transaction.amount.toString();
    } else {
      _titleController.clear();
      _amountController.clear();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => TransactionForm(
        titleController: _titleController,
        amountController: _amountController,
        initialType: transaction?.type ?? 'income',
        initialCategory: transaction?.category ?? 'Belanja',
        onSubmit: (title, amount, type, category, date) async {
          if (transaction == null) {
            await dbHelper.insertTransaction(
              Transaction(
                title: title,
                amount: amount,
                date: date,
                type: type,
                category: category,
              ),
            );
          } else {
            await dbHelper.updateTransaction(
              Transaction(
                id: transaction.id,
                title: title,
                amount: amount,
                date: transaction.date,
                type: type,
                category: category,
              ),
            );
          }

          Navigator.of(context).pop();
          _refreshTransactions();
        },
      ),
    );
  }

  void _deleteTransaction(int id) async {
    await dbHelper.deleteTransaction(id);
    _refreshTransactions();
  }

  int get _totalIncome => _transactions
      .where((t) => t.type == 'income')
      .fold(0, (sum, t) => sum + t.amount);

  int get _totalExpense => _transactions
      .where((t) => t.type == 'expense')
      .fold(0, (sum, t) => sum + t.amount);

  int get _totalSaldo => _totalIncome - _totalExpense;

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengelola Keuangan'),
        backgroundColor: Colors.yellow[700],
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CalendarScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.yellow[700],
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${selectedDate.year}',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                ),
                GestureDetector(
                  onTap: () => _selectMonth(context), // Make the month clickable
                  child: Row(
                    children: [
                      Text(
                        '${_getMonthName(selectedDate.month)}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      const Icon(Icons.arrow_drop_down, color: Colors.black),
                    ],
                  ),
                ),
                Text(
                  'Pengeluaran: ${_formatNumber(_totalExpense)}',
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
                Text(
                  'Pemasukan: ${_formatNumber(_totalIncome)}',
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
                Text(
                  'Saldo: ${_formatNumber(_totalSaldo)}',
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _transactions.length,
              itemBuilder: (ctx, i) {
                final t = _transactions[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                    t.type == 'income' ? Colors.green : Colors.pink,
                    child: Icon(
                      t.type == 'income' ? Icons.arrow_downward : Icons.fastfood,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(t.title),
                  subtitle: Text(
                      '${t.date.day} ${_getMonthName(t.date.month)} - ${t.type == 'income' ? 'Pemasukan' : 'Pengeluaran'}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rp ${_formatNumber(t.amount)}',
                        style: TextStyle(
                            color:
                            t.type == 'income' ? Colors.green : Colors.red),
                      ),
                      IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showForm(transaction: t)),
                      IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteTransaction(t.id!)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: Colors.yellow[700],
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const CustomBottomBar(),
    );
  }
}