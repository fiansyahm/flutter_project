// models/purchase_transaction.dart
class PurchaseTransaction {
  final int? id;
  final String items; // JSON string of items (e.g., [{"name": "barang a", "quantity": 2, "price": 10000}])
  final int total;
  final String paymentMethod;
  final String cashier;
  final String supplier;
  final int discount;
  final int tax;
  final DateTime date;

  PurchaseTransaction({
    this.id,
    required this.items,
    required this.total,
    required this.paymentMethod,
    required this.cashier,
    required this.supplier,
    required this.discount,
    required this.tax,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'items': items,
      'total': total,
      'paymentMethod': paymentMethod,
      'cashier': cashier,
      'supplier': supplier,
      'discount': discount,
      'tax': tax,
      'date': date.toIso8601String(),
    };
  }

  factory PurchaseTransaction.fromMap(Map<String, dynamic> map) {
    return PurchaseTransaction(
      id: map['id'],
      items: map['items'],
      total: map['total'],
      paymentMethod: map['paymentMethod'],
      cashier: map['cashier'],
      supplier: map['supplier'],
      discount: map['discount'],
      tax: map['tax'],
      date: DateTime.parse(map['date']),
    );
  }
}