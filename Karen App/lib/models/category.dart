// models/category.dart
import 'package:flutter/material.dart';

class Category {
  final String name;
  final IconData icon;

  Category({required this.name, required this.icon});
}

final List<Category> expenseCategories = [
  Category(name: 'Belanja', icon: Icons.shopping_cart),
  Category(name: 'Makanan', icon: Icons.fastfood),
  Category(name: 'Telepon', icon: Icons.phone),
  Category(name: 'Hiburan', icon: Icons.music_note),
  Category(name: 'Pendidikan', icon: Icons.book),
  Category(name: 'Kecantikan', icon: Icons.face),
  Category(name: 'Olahraga', icon: Icons.sports),
  Category(name: 'Sosial', icon: Icons.group),
  Category(name: 'Transportasi', icon: Icons.directions_bus),
  Category(name: 'Pakaian', icon: Icons.checkroom),
  Category(name: 'Mobil', icon: Icons.directions_car),
  Category(name: 'Minuman', icon: Icons.local_drink),
  Category(name: 'Rokok', icon: Icons.smoking_rooms),
  Category(name: 'Elektronik', icon: Icons.devices),
  Category(name: 'Bepergian', icon: Icons.flight),
  Category(name: 'Kesehatan', icon: Icons.medical_services),
  Category(name: 'Peliharaan', icon: Icons.pets),
  Category(name: 'Perbaikan', icon: Icons.build),
  Category(name: 'Perumahan', icon: Icons.home),
  Category(name: 'Rumah', icon: Icons.cabin),
  Category(name: 'Hadiah', icon: Icons.card_giftcard),
  Category(name: 'Donasi', icon: Icons.favorite),
  Category(name: 'Lotre', icon: Icons.casino),
  Category(name: 'Makanan ringan', icon: Icons.cake),
  Category(name: 'Anak-anak', icon: Icons.child_care),
  Category(name: 'Sayur-mayur', icon: Icons.local_florist),
  Category(name: 'Buah', icon: Icons.local_dining),
  Category(name: 'Pengaturan', icon: Icons.add),
];

final List<Category> incomeCategories = [
  Category(name: 'Gaji', icon: Icons.account_balance_wallet),
  Category(name: 'Bonus', icon: Icons.monetization_on),
  Category(name: 'Investasi', icon: Icons.trending_up),
  Category(name: 'Hadiah', icon: Icons.card_giftcard),
  Category(name: 'Lainnya', icon: Icons.add),
];