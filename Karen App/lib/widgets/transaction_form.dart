// widgets/transaction_form.dart
import 'package:flutter/material.dart';
import '../models/category.dart';

class TransactionForm extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController amountController;
  final String initialType;
  final String initialCategory;
  final Function(String, int, String, String, DateTime) onSubmit; // Updated type for amount

  const TransactionForm({
    super.key,
    required this.titleController,
    required this.amountController,
    required this.initialType,
    required this.initialCategory,
    required this.onSubmit,
  });

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  late String selectedType;
  late String selectedCategory;
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    selectedType = widget.initialType;
    selectedCategory = widget.initialCategory;
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tabs
          Container(
            color: Colors.yellow[700],
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedType = 'expense';
                        selectedCategory = expenseCategories[0].name; // Reset category
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      color: selectedType == 'expense'
                          ? Colors.black
                          : Colors.yellow[700],
                      child: Center(
                        child: Text(
                          'Pengeluaran',
                          style: TextStyle(
                            color: selectedType == 'expense'
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedType = 'income';
                        selectedCategory = incomeCategories[0].name; // Reset category
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      color: selectedType == 'income'
                          ? Colors.black
                          : Colors.yellow[700],
                      child: Center(
                        child: Text(
                          'Pemasukan',
                          style: TextStyle(
                            color: selectedType == 'income'
                                ? Colors.white
                                : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedType = 'transfer';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      color: selectedType == 'transfer'
                          ? Colors.black
                          : Colors.yellow[700],
                      child: const Center(
                        child: Text(
                          'Transfer',
                          style: TextStyle(
                            color: Colors.black,
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
          // Category Grid
          Container(
            height: 300,
            child: GridView.count(
              crossAxisCount: 4,
              children: (selectedType == 'income'
                  ? incomeCategories
                  : expenseCategories)
                  .map((category) => GestureDetector(
                onTap: () {
                  setState(() {
                    selectedCategory = category.name;
                  });
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      backgroundColor:
                      selectedCategory == category.name
                          ? Colors.yellow[700]
                          : Colors.grey[200],
                      child: Icon(
                        category.icon,
                        color: selectedCategory == category.name
                            ? Colors.black
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(category.name),
                  ],
                ),
              ))
                  .toList(),
            ),
          ),
          // Form Fields
          TextField(
            controller: widget.titleController,
            decoration: const InputDecoration(
              labelText: 'Catatan',
              hintText: 'Masukkan catatan...',
            ),
          ),
          TextField(
            controller: widget.amountController,
            decoration: const InputDecoration(labelText: 'Jumlah'),
            keyboardType: TextInputType.number,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => _selectDate(context),
                child: const Text('Hari ini'),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () {
                      final title = widget.titleController.text;
                      final amount =
                          int.tryParse(widget.amountController.text) ?? 0; // Convert to int
                      widget.onSubmit(
                          title, amount, selectedType, selectedCategory, selectedDate);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}