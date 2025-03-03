import 'package:flutter/material.dart';

class DetailPahlawan extends StatelessWidget {
  final String title, category, img;
  final List<Map<String, String>> description;

  const DetailPahlawan({
    Key? key,
    required this.title,
    required this.category,
    required this.img,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar utama
            Image.network(
              img,
              fit: BoxFit.cover,
              width: double.infinity,
              height: 250,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 250,
                color: Colors.grey,
                child: const Center(
                  child: Icon(Icons.broken_image, size: 50, color: Colors.white),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama dan deskripsi
                  Text(
                    title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  // Judul section "Lahir"
                  const Text(
                    "Description:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // Konten lahir
                  description.isEmpty
                      ? const Text(
                    "Data tidak tersedia.",
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  )
                      : Column(
                    children: description.map((item) => _buildContent(item)).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(Map<String, String> item) {
    // Validasi type dan value
    final type = item['type'];
    final value = item['value'];

    if (type == null || value == null) {
      return const SizedBox.shrink(); // Kosong jika data tidak valid
    }

    switch (type) {
      case 'text':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        );
      case 'image':
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Image.network(
            value,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              height: 150,
              color: Colors.grey,
              child: const Center(
                child: Icon(Icons.broken_image, size: 50, color: Colors.white),
              ),
            ),
          ),
        );
      default:
        return const SizedBox.shrink(); // Kosong untuk type yang tidak dikenal
    }
  }
}
