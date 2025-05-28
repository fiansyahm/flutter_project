// models/transaction.dart
class Transaction {
  final int? id;
  final String title;
  final int amount;
  final DateTime date;
  final String type; // 'income' or 'expense'
  final String category; // New field for category

  Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type,
      'category': category,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      type: map['type'],
      category: map['category'],
    );
  }
}