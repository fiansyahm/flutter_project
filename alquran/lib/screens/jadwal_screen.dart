import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/city_model.dart';
import '../models/jadwal_model.dart';
import '../services/jadwal_service.dart';

class JadwalScreen extends StatefulWidget {
  @override
  _JadwalScreenState createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen> {
  final JadwalService jadwalService = JadwalService();
  List<City> cities = [];
  Jadwal? jadwal;
  String selectedCity = '';
  bool isLoading = false;
  bool isCitySelected = false; // Tambahkan variabel untuk menandai apakah kota sudah dipilih

  // Fungsi untuk mencari kota
  void searchCity(String query) async {
    setState(() {
      isLoading = true;
      isCitySelected = false; // Reset status kota dipilih
    });

    try {
      List<City> result = await jadwalService.getCities(query);
      setState(() {
        cities = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data kota: $e')),
      );
    }
  }

  // Fungsi untuk mengambil jadwal sholat
  void fetchJadwal(String cityId, String cityName) async {
    setState(() {
      isLoading = true;
      isCitySelected = true; // Set status kota sudah dipilih
      selectedCity = cityName;
    });

    try {
      Jadwal result = await jadwalService.getJadwal(cityId);
      setState(() {
        jadwal = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat jadwal sholat: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jadwal Sholat'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Input pencarian kota
            TextField(
              decoration: InputDecoration(
                labelText: 'Cari Kota/Kabupaten',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) {
                  searchCity(value);
                } else {
                  setState(() {
                    cities = []; // Kosongkan daftar kota jika input kosong
                    isCitySelected = false; // Reset status kota dipilih
                  });
                }
              },
            ),
            SizedBox(height: 16),
            // Daftar kota (hanya muncul jika kota belum dipilih)
            if (!isCitySelected && cities.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: cities.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(cities[index].lokasi),
                      onTap: () {
                        fetchJadwal(cities[index].id, cities[index].lokasi);
                      },
                    );
                  },
                ),
              ),
            SizedBox(height: 16),
            // Jadwal sholat (muncul setelah kota dipilih)
            if (isCitySelected && jadwal != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jadwal Sholat $selectedCity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Tanggal: ${jadwal!.tanggal}'),
                  Text('Imsak: ${jadwal!.imsak}'),
                  Text('Subuh: ${jadwal!.subuh}'),
                  Text('Terbit: ${jadwal!.terbit}'),
                  Text('Dhuha: ${jadwal!.dhuha}'),
                  Text('Dzuhur: ${jadwal!.dzuhur}'),
                  Text('Ashar: ${jadwal!.ashar}'),
                  Text('Maghrib: ${jadwal!.maghrib}'),
                  Text('Isya: ${jadwal!.isya}'),
                ],
              ),
            // Loading indicator
            if (isLoading)
              Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}