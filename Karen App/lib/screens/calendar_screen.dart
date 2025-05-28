import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/database_helper.dart';
import '../models/transaction.dart';

class CalendarScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isGoldTheme;

  const CalendarScreen({super.key, required this.onThemeToggle, required this.isGoldTheme});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final DatabaseHelper dbHelper = DatabaseHelper();
  DateTime selectedDate = DateTime.now();
  List<Transaction> transactions = [];

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

  Future<void> _selectMonth(BuildContext context) async {
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

  @override
  Widget build(BuildContext context) {
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final firstDayWeekday = firstDayOfMonth.weekday % 7;

    List<Widget> dayWidgets = [];
    for (int i = 0; i < firstDayWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final currentDay = DateTime(selectedDate.year, selectedDate.month, day);
      final dayTransactions = transactions.where((t) {
        try {
          final transactionDate = DateTime.parse(t.date);
          return transactionDate.year == currentDay.year &&
              transactionDate.month == currentDay.month &&
              transactionDate.day == currentDay.day;
        } catch (e) {
          print('Error parsing date: ${t.date}');
          return false;
        }
      }).toList();
      final income = dayTransactions
          .where((t) => t.type == 'income')
          .fold(0, (sum, t) => sum + t.amount);
      final expense = dayTransactions
          .where((t) => t.type == 'expense')
          .fold(0, (sum, t) => sum + t.amount);

      dayWidgets.add(
        GestureDetector(
          onTap: () {
            if (dayTransactions.isNotEmpty) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('$day ${_getMonthName(selectedDate.month)} ${selectedDate.year}'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView(
                      shrinkWrap: true,
                      children: dayTransactions
                          .map((t) => ListTile(
                        title: Text(t.title),
                        subtitle: Text('Rp ${t.amount} - ${t.category}'),
                        trailing: Text(t.type == 'income' ? 'Pemasukan' : 'Pengeluaran'),
                      ))
                          .toList(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: income > 0 || expense > 0 ? Colors.green[100] : null,
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('$day', style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
                if (income > 0)
                  Text(
                    '${(income / 1000).toStringAsFixed(0)}K',
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                if (expense > 0)
                  Text(
                    '${(expense / 1000).toStringAsFixed(0)}K',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Kalender',
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _selectMonth(context),
              child: Row(
                children: [
                  Text(
                    '${_getMonthName(selectedDate.month)} ${selectedDate.year}',
                    style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  ),
                  Icon(Icons.arrow_drop_down,
                      color: Theme.of(context).textTheme.bodyLarge?.color),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              Text('Min'),
              Text('Sen'),
              Text('Sel'),
              Text('Rab'),
              Text('Kam'),
              Text('Jum'),
              Text('Sab'),
            ],
          ),
          const Divider(),
          Expanded(
            child: GridView.count(
              crossAxisCount: 7,
              children: dayWidgets,
            ),
          ),
        ],
      ),
    );
  }
}