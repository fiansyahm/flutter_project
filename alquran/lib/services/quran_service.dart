import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ayat.dart';
import '../models/surah.dart';

class QuranService {
  final String baseUrl = "https://api.alquran.cloud/v1";
  final String baseUrlIndo = "https://quran-api.santrikoding.com/api";

  Future<List<Surah>> getSurahs() async {
    final response = await http.get(Uri.parse('$baseUrl/surah'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body)['data'];
      return data.map((surah) => Surah.fromJson(surah)).toList();
    } else {
      throw Exception('Failed to load surahs');
    }
  }

  // Method untuk mengambil ayat-ayat dari sebuah surat
  Future<List<Ayat>> getAyat(int surahNumber) async {
    final response = await http.get(Uri.parse('$baseUrlIndo/surah/$surahNumber'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body)['ayat'];
      return data.map((ayat) => Ayat.fromJson(ayat)).toList();
    } else {
      throw Exception('Gagal memuat ayat');
    }
  }
}