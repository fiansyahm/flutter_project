import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../models/surah.dart';
import '../models/ayat.dart';
import '../services/quran_service.dart';

class SurahDetailScreen extends StatefulWidget {
  final Surah surah;

  SurahDetailScreen({required this.surah});

  @override
  _SurahDetailScreenState createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  late Future<List<Ayat>> futureAyat;
  final QuranService quranService = QuranService();

  @override
  void initState() {
    super.initState();
    futureAyat = quranService.getAyat(widget.surah.number);
  }

  String _removeHtmlTags(String htmlText) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlText.replaceAll(exp, '');
  }

  // Calculate Juz number (simplified for demo purposes)
  String _getJuzNumber() {
    // Simplified logic: Juz 1 includes Surah 1 (Al-Fatihah) to Surah 2 (Al-Baqarah) up to a certain ayah
    // In a real app, use a more precise mapping of ayahs to Juz
    return widget.surah.number <= 2 ? 'JUZ 1' : 'JUZ ${widget.surah.number ~/ 4 + 1}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_getJuzNumber()),
            Text(widget.surah.name, style: TextStyle(fontFamily: 'Arabic', fontSize: 20)),
            Text('${widget.surah.number}. ${widget.surah.englishName}'),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_drop_down),
            onPressed: () {
              // Add functionality for dropdown if needed
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.surah.revelationType, // e.g., "Mekah"
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
                Text(
                  widget.surah.englishName, // e.g., "Pembukaan"
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${widget.surah.numberOfAyahs} Ayat',
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ],
            ),
          ),
          // Ayat List
          Expanded(
            child: FutureBuilder<List<Ayat>>(
              future: futureAyat,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: SpinKitFadingCircle(
                      color: Colors.blue,
                      size: 50.0,
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text('Tidak ada data ayat'),
                  );
                } else {
                  List<Ayat> ayatList = snapshot.data!;
                  return ListView.builder(
                    itemCount: ayatList.length,
                    itemBuilder: (context, index) {
                      Ayat ayat = ayatList[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Ayat Number
                            CircleAvatar(
                              backgroundColor: Colors.transparent,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(
                                    Icons.star_border,
                                    color: Colors.brown,
                                    size: 40,
                                  ),
                                  Text(
                                    '${ayat.nomor}',
                                    style: TextStyle(
                                      color: Colors.brown,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16),
                            // Ayat Content
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Arabic Text
                                  Text(
                                    ayat.ar,
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontFamily: 'Arabic', // Use an Arabic font
                                      color: Colors.black,
                                    ),
                                    textDirection: TextDirection.rtl,
                                    textAlign: TextAlign.right,
                                  ),
                                  SizedBox(height: 8),
                                  // Transliterasi
                                  Text(
                                    _removeHtmlTags(ayat.tr),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                  SizedBox(height: 8),
                                  // Terjemahan
                                  Text(
                                    ayat.idn,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                  SizedBox(height: 8),
                                  // Separator
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.star, size: 10, color: Colors.brown),
                                      SizedBox(width: 8),
                                      Icon(Icons.star, size: 10, color: Colors.brown),
                                      SizedBox(width: 8),
                                      Icon(Icons.star, size: 10, color: Colors.brown),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}