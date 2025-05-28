import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Box<Transaction>? _transactionBox;

  Future<void> initHive() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TransactionAdapter());
    _transactionBox = await Hive.openBox<Transaction>('transactions');
  }

  Future<Box<Transaction>> get transactionBox async {
    if (_transactionBox == null || !_transactionBox!.isOpen) {
      _transactionBox = await Hive.openBox<Transaction>('transactions');
    }
    return _transactionBox!;
  }

  Future<List<Transaction>> getTransactions() async {
    final box = await transactionBox;
    final transactions = box.values.toList();
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }

  Future<void> insertTransaction(Transaction transaction) async {
    final box = await transactionBox;
    final newTransaction = transaction.id == null
        ? Transaction(
      id: box.length + 1,
      title: transaction.title,
      amount: transaction.amount,
      date: transaction.date,
      type: transaction.type,
      category: transaction.category,
    )
        : transaction;
    await box.put(newTransaction.id, newTransaction);
  }

  Future<void> updateTransaction(Transaction transaction) async {
    final box = await transactionBox;
    if (transaction.id != null) {
      await box.put(transaction.id, transaction);
    }
  }

  Future<void> deleteTransaction(int id) async {
    final box = await transactionBox;
    await box.delete(id);
  }

  Future<void> close() async {
    if (_transactionBox != null && _transactionBox!.isOpen) {
      await _transactionBox!.close();
    }
  }
}