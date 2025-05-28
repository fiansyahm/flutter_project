import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'calendar_screen.dart';
import 'report_screen.dart';
import 'profile_screen.dart'; // Import the new screen
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
  bool isGoldTheme = true; // Default to Gold theme

  @override
  void initState() {
    super.initState();
    _refreshTransactions();
  }

  Future<void> _refreshTransactions() async {
    final data = await dbHelper.getTransactions();
    setState(() {
      _transactions = data.where((t) {
        try {
          final parsedDate = DateTime.parse(t.date);
          return parsedDate.year == selectedDate.year &&
              parsedDate.month == selectedDate.month;
        } catch (e) {
          print('Error parsing date: ${t.date}');
          return false;
        }
      }).toList();
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
        initialDate: transaction?.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
        onSubmit: (title, amount, type, category, date) async {
          final formattedDate = date;
          if (transaction == null) {
            await dbHelper.insertTransaction(
              Transaction(
                title: title,
                amount: amount,
                date: formattedDate,
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
                date: formattedDate,
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

  void _toggleTheme() {
    setState(() {
      isGoldTheme = !isGoldTheme;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: isGoldTheme
          ? ThemeData(
        primaryColor: Colors.yellow[700],
        scaffoldBackgroundColor: Colors.grey[200],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.yellow[700],
          foregroundColor: Colors.black,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.yellow[700],
        ),
      )
          : ThemeData(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.black,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: Builder(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Pengelola Keuangan'),
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
                color: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${selectedDate.year}',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _selectMonth(context),
                          child: Row(
                            children: [
                              Text(
                                _getMonthName(selectedDate.month),
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).textTheme.bodyLarge?.color),
                              ),
                              Icon(Icons.arrow_drop_down,
                                  color: Theme.of(context).textTheme.bodyLarge?.color),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pengeluaran: ${_formatNumber(_totalExpense)}',
                          style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                        Text(
                          'Pemasukan: ${_formatNumber(_totalIncome)}',
                          style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                        Text(
                          'Saldo: ${_formatNumber(_totalSaldo)}',
                          style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshTransactions,
                  child: ListView.builder(
                    itemCount: _transactions.length,
                    itemBuilder: (ctx, i) {
                      final t = _transactions[i];
                      DateTime parsedDate;
                      try {
                        parsedDate = DateTime.parse(t.date);
                      } catch (e) {
                        parsedDate = DateTime.now();
                        print('Error parsing date: ${t.date}');
                      }
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                          t.type == 'income' ? Colors.green : Colors.pink,
                          child: Icon(
                            t.type == 'income'
                                ? Icons.arrow_downward
                                : Icons.fastfood,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(t.title,
                            style: TextStyle(
                                color: Theme.of(context).textTheme.bodyLarge?.color)),
                        subtitle: Text(
                            '${parsedDate.day} ${_getMonthName(parsedDate.month)} - ${t.type == 'income' ? 'Pemasukan' : 'Pengeluaran'}',
                            style: TextStyle(
                                color: Theme.of(context).textTheme.bodyLarge?.color)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Rp ${_formatNumber(t.amount)}',
                              style: TextStyle(
                                  color: t.type == 'income'
                                      ? Colors.green
                                      : Colors.red),
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
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showForm(),
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
            child: const Icon(Icons.add),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: CustomBottomBar(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}