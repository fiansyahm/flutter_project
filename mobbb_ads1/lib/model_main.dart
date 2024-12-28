import 'dart:convert'; // Untuk decoding JSON

class ModelMain {
  String? title;
  String? category;
  List<Map<String, String>>? description;
  String? img;
  String? level;

  // Konstruktor
  ModelMain(
      this.title,
      this.category,
      this.description,
      this.img,
      this.level,
      );

  // Konstruktor dari JSON
  ModelMain.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    category = json['category'];
    if (json['description'] != null) {
      description = (json['description'] as List)
          .map((e) => Map<String, String>.from(e as Map))
          .toList();
    }
    img = json['img'];
    level=json['level'];

  }

  // Metode untuk mengubah objek menjadi JSON
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'category': category,
      'description': description,
      'img': img,
      'level':level,
    };
  }
}
