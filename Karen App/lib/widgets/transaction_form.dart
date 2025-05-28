import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';

class TransactionForm extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController amountController;
  final String initialType;
  final String initialCategory;
  final String initialDate;
  final Function(String, int, String, String, String) onSubmit;

  const TransactionForm({
    super.key,
    required this.titleController,
    required this.amountController,
    required this.initialType,
    required this.initialCategory,
    required this.initialDate,
    required this.onSubmit,
  });

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  late String selectedType;
  late String selectedCategory;
  late DateTime selectedDate;

  @override
  void initState() {
    super.initState();
    selectedType = widget.initialType;
    selectedCategory = widget.initialCategory;
    try {
      selectedDate = DateTime.parse(widget.initialDate);
    } catch (e) {
      selectedDate = DateTime.now();
      print('Error parsing initial date: ${widget.initialDate}');
    }
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
              onPrimary: Colors.black, // Force black text in date picker
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center, // Center align content
          children: [
            // Tabs
            Container(
              color: Theme.of(context).primaryColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center, // Center tabs
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedType = 'expense';
                          selectedCategory = expenseCategories[0].name;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        color: selectedType == 'expense'
                            ? Colors.grey[800]
                            : Theme.of(context).primaryColor,
                        child: Center(
                          child: Text(
                            'Pengeluaran',
                            style: const TextStyle(
                              color: Colors.black, // Force black text
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
                          selectedCategory = incomeCategories[0].name;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        color: selectedType == 'income'
                            ? Colors.grey[800]
                            : Theme.of(context).primaryColor,
                        child: Center(
                          child: Text(
                            'Pemasukan',
                            style: const TextStyle(
                              color: Colors.black, // Force black text
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
                          selectedCategory = 'Transfer';
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        color: selectedType == 'transfer'
                            ? Colors.grey[800]
                            : Theme.of(context).primaryColor,
                        child: Center(
                          child: Text(
                            'Transfer',
                            style: const TextStyle(
                              color: Colors.black, // Force black text
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
            if (selectedType != 'transfer')
              Container(
                height: 200,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: GridView.count(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  children: (selectedType == 'income' ? incomeCategories : expenseCategories)
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
                          backgroundColor: selectedCategory == category.name
                              ? Theme.of(context).primaryColor
                              : Colors.grey[200],
                          child: Icon(
                            category.icon,
                            color: selectedCategory == category.name
                                ? Colors.black // Force black icon
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          category.name,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black, // Force black text
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ))
                      .toList(),
                ),
              ),
            // Form Fields
            TextField(
              readOnly: true,
              onTap: () => _selectDate(context),
              style: const TextStyle(color: Colors.black), // Force black text
              decoration: InputDecoration(
                labelText: 'Tanggal',
                labelStyle: const TextStyle(color: Colors.black), // Force black text
                hintText: DateFormat('yyyy-MM-dd').format(selectedDate),
                hintStyle: const TextStyle(color: Colors.black54), // Slightly lighter black
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(
                  Icons.calendar_today,
                  color: Colors.black, // Force black icon
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.amountController,
              style: const TextStyle(color: Colors.black), // Force black text
              decoration: InputDecoration(
                labelText: 'Jumlah',
                labelStyle: const TextStyle(color: Colors.black), // Force black text
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.titleController,
              style: const TextStyle(color: Colors.black), // Force black text
              decoration: InputDecoration(
                labelText: 'Catatan',
                labelStyle: const TextStyle(color: Colors.black), // Force black text
                hintText: 'Masukkan catatan...',
                hintStyle: const TextStyle(color: Colors.black54), // Slightly lighter black
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => _selectDate(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.black, // Force black text
                  ),
                  child: Text(
                    DateFormat('dd MMM yyyy').format(selectedDate), // Matches image format
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Colors.black, // Force black icon
                      ),
                      onPressed: () {
                        // Implementasi scan kamera
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.check,
                        color: Colors.black, // Force black icon
                      ),
                      onPressed: () {
                        final title = widget.titleController.text.trim();
                        final amount = int.tryParse(widget.amountController.text) ?? 0;
                        if (title.isEmpty || amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Judul dan jumlah harus valid')),
                          );
                          return;
                        }
                        widget.onSubmit(
                          title,
                          amount,
                          selectedType,
                          selectedCategory,
                          DateFormat('yyyy-MM-dd').format(selectedDate),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}