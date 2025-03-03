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

  @override
  Widget build(BuildContext context) {
    String _removeHtmlTags(String htmlText) {
      // Menghapus tag HTML menggunakan regex
      RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
      return htmlText.replaceAll(exp, '');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.surah.name),
      ),
      body: FutureBuilder<List<Ayat>>(
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
                return Container(
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Teks Arab
                      Text(
                        ayat.ar,
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'UthmanicHafs', // Gunakan font Arabic
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      SizedBox(height: 8),
                      // Transliterasi
                      Text(
                        _removeHtmlTags(ayat.tr), // Menghapus tag HTML
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.end,
                      ),
                      SizedBox(height: 8),
                      // Terjemahan
                      Text(
                        ayat.idn,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.start, // Rata kiri untuk terjemahan
                      ),
                      SizedBox(height: 8),
                      // Nomor Ayat
                      Text(
                        'Ayat ${ayat.nomor}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.end,
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}