import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../models/surah.dart';
import '../services/quran_service.dart';
import 'surah_detail_screen.dart';

class QuranScreen extends StatefulWidget {
  @override
  _QuranScreenState createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  late Future<List<Surah>> futureSurahs;
  final QuranService quranService = QuranService();

  @override
  void initState() {
    super.initState();
    futureSurahs = quranService.getSurahs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Surat Al-Quran'),
      ),
      body: FutureBuilder<List<Surah>>(
        future: futureSurahs,
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
              child: Text('Tidak ada data'),
            );
          } else {
            List<Surah> surahs = snapshot.data!;
            return ListView.builder(
              itemCount: surahs.length,
              itemBuilder: (context, index) {
                Surah surah = surahs[index];
                return ListTile(
                  title: Text(surah.name), // Nama surat dalam bahasa Arab
                  subtitle: Text(surah.englishName), // Terjemahan
                  trailing: Text('Ayat: ${surah.numberOfAyahs}'),
                  onTap: () {
                    // Navigasi ke halaman detail surat
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SurahDetailScreen(surah: surah),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}