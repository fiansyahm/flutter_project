import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'quran_screen.dart';
import 'jadwal_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const MethodChannel _channel = MethodChannel('com.example.mobbb_ads/ad');

  @override
  void initState() {
    super.initState();
    _showAdIfNeeded(); // Menampilkan iklan saat pertama kali aplikasi dibuka
  }

  // Fungsi untuk menampilkan iklan
  Future<void> _showAdIfNeeded() async {
    try {
      await _channel.invokeMethod('showAd');
      print('Iklan berhasil ditampilkan');
    } on PlatformException catch (e) {
      print('Gagal menampilkan iklan: ${e.message}');
    } catch (e) {
      print('Terjadi kesalahan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Aplikasi Al-Quran'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                // await _showAdIfNeeded();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => QuranScreen()),
                );
              },
              child: Text('Al-Quran', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await _showAdIfNeeded();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => JadwalScreen()),
                );
              },
              child: Text('Jadwal Sholat', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Keluar', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
