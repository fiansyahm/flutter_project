import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';

class TransactionForm extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController amountController;
  final String initialType;
  final String initialCategory;
  final String initialDate; // Changed to String
  final Function(String, int, String, String, String) onSubmit; // Updated to expect String for date

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
      child: SingleChildScrollView(
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
                          selectedCategory = expenseCategories[0].name;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        color: selectedType == 'expense' ? Colors.black : Colors.yellow[700],
                        child: Center(
                          child: Text(
                            'Pengeluaran',
                            style: TextStyle(
                              color: selectedType == 'expense' ? Colors.white : Colors.black,
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
                        color: selectedType == 'income' ? Colors.black : Colors.yellow[700],
                        child: Center(
                          child: Text(
                            'Pemasukan',
                            style: TextStyle(
                              color: selectedType == 'income' ? Colors.white : Colors.black,
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
                          selectedCategory = 'Transfer'; // Default category for transfer
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        color: selectedType == 'transfer' ? Colors.black : Colors.yellow[700],
                        child: Center(
                          child: Text(
                            'Transfer',
                            style: TextStyle(
                              color: selectedType == 'transfer' ? Colors.white : Colors.black,
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
            if (selectedType != 'transfer') // Hide category grid for transfer
              Container(
                height: 200, // Reduced height for better UX
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
                        Text(
                          category.name,
                          style: const TextStyle(fontSize: 12),
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
              decoration: InputDecoration(
                labelText: 'Tanggal',
                hintText: DateFormat('yyyy-MM-dd').format(selectedDate),
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.amountController,
              decoration: const InputDecoration(
                labelText: 'Jumlah',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: widget.titleController,
              decoration: const InputDecoration(
                labelText: 'Catatan',
                hintText: 'Masukkan catatan...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => _selectDate(context),
                  child: Text(DateFormat('dd MMM yyyy').format(selectedDate)),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: () {
                        // Implementasi scan kamera
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.check),
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
                          DateFormat('yyyy-MM-dd').format(selectedDate), // Convert to String
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