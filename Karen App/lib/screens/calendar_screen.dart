// screens/calendar_screen.dart
import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/transaction.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

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
      transactions = allTransactions
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
    // Calculate the first day of the month and the number of days
    final firstDayOfMonth = DateTime(selectedDate.year, selectedDate.month, 1);
    final daysInMonth = DateTime(selectedDate.year, selectedDate.month + 1, 0).day;
    final firstDayWeekday = firstDayOfMonth.weekday % 7; // Adjust for Sunday start

    // Create a list of days with their transactions
    List<Widget> dayWidgets = [];
    for (int i = 0; i < firstDayWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final currentDay = DateTime(selectedDate.year, selectedDate.month, day);
      final dayTransactions = transactions
          .where((t) =>
      t.date.year == currentDay.year &&
          t.date.month == currentDay.month &&
          t.date.day == currentDay.day)
          .toList();
      final income = dayTransactions
          .where((t) => t.type == 'income')
          .fold(0, (sum, t) => sum + t.amount);
      final expense = dayTransactions
          .where((t) => t.type == 'expense')
          .fold(0, (sum, t) => sum + t.amount);

      dayWidgets.add(
        Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: income > 0 || expense > 0 ? Colors.green[100] : null,
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('$day'),
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
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Kalender',
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => _selectMonth(context),
              child: Row(
                children: [
                  Text(
                    '${_getMonthName(selectedDate.month)} ${selectedDate.year}',
                    style: const TextStyle(color: Colors.black),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.black),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.yellow[700],
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Days of the week
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
          // Calendar grid
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