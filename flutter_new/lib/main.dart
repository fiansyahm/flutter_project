import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ReceiptApp(),
    );
  }
}

class ReceiptApp extends StatefulWidget {
  @override
  _ReceiptAppState createState() => _ReceiptAppState();
}

class _ReceiptAppState extends State<ReceiptApp> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final _nameController = TextEditingController();
  final _regionController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  String _paymentMethod = 'Tunai';
  String _cashierName = '';
  String _editingKey = ''; // To track the record being edited

  Future<void> _selectDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      _dateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      _timeController.text = pickedTime.format(context);
    }
  }

  void _addOrUpdateRecord() {
    if (_formKey.currentState!.validate()) {
      final newRecord = {
        'date': _dateController.text,
        'time': _timeController.text,
        'name': _nameController.text,
        'region': _regionController.text,
        'amount': _amountController.text,
        'payment': _paymentMethod,
        'cashier': _cashierName,
      };

      if (_editingKey.isEmpty) {
        // Add new record
        _database.child('records').push().set(newRecord).then((_) {
          // Clear the form after saving the record
          _clearForm();
        });
      } else {
        // Update existing record
        _database.child('records').child(_editingKey).set(newRecord).then((_) {
          setState(() {
            _editingKey = ''; // Reset the editing state
          });

          // Clear the form after saving the record
          _clearForm();
        });
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _regionController.clear();
    _amountController.clear();
    _dateController.clear();
    _timeController.clear();
    _paymentMethod = 'Tunai';
    _cashierName = '';
  }

  void _deleteRecord(String key) {
    _database.child('records').child(key).remove().then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Record deleted successfully')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting record: $error')),
      );
    });
  }

  void _editRecord(Map<String, dynamic> record, String key) {
    _editingKey = key;
    _nameController.text = record['name'];
    _regionController.text = record['region'];
    _amountController.text = record['amount'];
    _dateController.text = record['date'];
    _timeController.text = record['time'];
    _paymentMethod = record['payment'];
    _cashierName = record['cashier'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Record & Print Receipt'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _dateController,
                decoration: InputDecoration(
                  labelText: 'Tanggal',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.calendar_today),
                    onPressed: _selectDate,
                  ),
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Tanggal tidak boleh kosong';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _timeController,
                decoration: InputDecoration(
                  labelText: 'Jam',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.access_time),
                    onPressed: _selectTime,
                  ),
                ),
                readOnly: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Jam tidak boleh kosong';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nama'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _regionController,
                decoration: InputDecoration(labelText: 'Daerah'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Daerah tidak boleh kosong';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Nominal (Rp)'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nominal tidak boleh kosong';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _paymentMethod,
                decoration: InputDecoration(labelText: 'Via'),
                items: ['Tunai', 'Transfer', 'EDC']
                    .map((method) => DropdownMenuItem(
                  value: method,
                  child: Text(method),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _paymentMethod = value!;
                  });
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Kasir'),
                onChanged: (value) {
                  _cashierName = value;
                },
              ),
              SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _addOrUpdateRecord,
                child: Text(_editingKey.isEmpty ? 'Simpan' : 'Update'),
              ),
              SizedBox(height: 20.0),
              // StreamBuilder to listen to Firebase data and display it
              StreamBuilder(
                stream: _database.child('records').onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Something went wrong'));
                  }
                  final data = snapshot.data as DatabaseEvent;
                  final records = data.snapshot.value as Map? ?? {};
                  final List<Map<String, dynamic>> recordsList = [];

                  records.forEach((key, value) {
                    final record = Map<String, dynamic>.from(value as Map);
                    record['key'] = key; // Store the key for reference
                    recordsList.add(record);
                  });

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: recordsList.length,
                    itemBuilder: (context, index) {
                      final record = recordsList[index];
                      final key = record['key']; // Use the stored key

                      return ListTile(
                        title: Text('${record['name']} - ${record['amount']}'),
                        subtitle: Text(
                            'Tanggal: ${record['date']} - Jam: ${record['time']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                _editRecord(record, key);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () {
                                _deleteRecord(key); // Delete using the correct key
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
