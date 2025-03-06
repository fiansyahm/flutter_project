import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:convert';
import '../models/city_model.dart';
import '../models/jadwal_model.dart';
import '../services/jadwal_service.dart';

class JadwalScreen extends StatefulWidget {
  @override
  _JadwalScreenState createState() => _JadwalScreenState();
}

class _JadwalScreenState extends State<JadwalScreen> {
  final JadwalService jadwalService = JadwalService();
  Jadwal? jadwal;
  String selectedCity = 'Memuat lokasi...';
  bool isLoading = false;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  DateTime? nextPrayerTime;
  String nextPrayerName = '';
  Duration? timeUntilNextPrayer;
  late tz.Location jakartaTimezone;

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones(); // Initialize timezone database
    jakartaTimezone = tz.getLocation('Asia/Jakarta'); // Set timezone to Asia/Jakarta
    _initializeNotifications();
    _getCurrentLocation();
    _startPrayerCountdown();
  }

  // Initialize notifications
  Future<void> _initializeNotifications() async {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
    InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Get current location and fetch prayer times
  Future<void> _getCurrentLocation() async {
    setState(() => isLoading = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak');
        }
      }

      String cityName = await getCityName();
      String cityId = await _getCityIdFromCoordinates(cityName);
      Jadwal result = await jadwalService.getJadwal(cityId);
      setState(() {
        jadwal = result;
        selectedCity = cityName; // Update with cleaned city name
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        selectedCity = 'Gagal memuat lokasi';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat jadwal sholat: $e')),
      );
    }
  }

  // Get city name from coordinates using geocoding and remove prefixes
  Future<String> getCityName() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        // Use subAdministrativeArea for city name and remove "Kabupaten" or "Kota"
        String? city = placemarks.first.subAdministrativeArea;
        if (city != null && city.isNotEmpty) {
          city = city.replaceAll('Kabupaten ', '').replaceAll('Kota ', '');
          return city;
        }
        return 'Unknown City';
      } else {
        return 'City not found';
      }
    } catch (e) {
      return 'Jakarta'; // Fallback to Jakarta
    }
  }

  // Fetch city ID from MyQuran API
  Future<String> _getCityIdFromCoordinates(String cityName) async {
    try {
      List<City> result = await jadwalService.getCities(cityName);
      if (result.isNotEmpty) {
        setState(() {
          selectedCity = result[0].lokasi; // Update with precise city name from API
        });
        return result[0].id; // Return the first matching city's ID
      } else {
        setState(() {
          selectedCity = 'Jakarta (Fallback)';
        });
        return '1301'; // Fallback to Jakarta
      }
    } catch (e) {
      setState(() {
        selectedCity = 'Jakarta (Fallback)';
      });
      print('Error fetching city ID: $e');
      return '1301'; // Fallback to Jakarta
    }
  }

  // Start countdown for next prayer
  void _startPrayerCountdown() {
    Future.delayed(Duration(seconds: 1), () {
      if (jadwal != null) {
        tz.TZDateTime now = tz.TZDateTime.now(jakartaTimezone);
        List<Map<String, String>> prayerTimes = [
          {'name': 'Imsak', 'time': jadwal!.imsak},
          {'name': 'Subuh', 'time': jadwal!.subuh},
          {'name': 'Terbit', 'time': jadwal!.terbit},
          {'name': 'Dhuha', 'time': jadwal!.dhuha},
          {'name': 'Dzuhur', 'time': jadwal!.dzuhur},
          {'name': 'Ashar', 'time': jadwal!.ashar},
          {'name': 'Maghrib', 'time': jadwal!.maghrib},
          {'name': 'Isya', 'time': jadwal!.isya},
        ];

        DateFormat timeFormat = DateFormat('HH:mm');
        nextPrayerTime = null;
        nextPrayerName = '';

        for (var prayer in prayerTimes) {
          DateTime prayerTime = timeFormat.parse(prayer['time']!);
          tz.TZDateTime todayPrayerTime = tz.TZDateTime(
            jakartaTimezone,
            now.year,
            now.month,
            now.day,
            prayerTime.hour,
            prayerTime.minute,
          );
          if (todayPrayerTime.isAfter(now)) {
            nextPrayerTime = todayPrayerTime;
            nextPrayerName = prayer['name']!;
            break;
          }
        }

        if (nextPrayerTime != null) {
          timeUntilNextPrayer = nextPrayerTime!.difference(now);
        }

        setState(() {});
        _startPrayerCountdown(); // Recursive call to update every second
      }
    });
  }

  // Schedule notification for prayer time using zonedSchedule
  Future<void> _scheduleNotification(String prayerName, String time) async {
    DateFormat timeFormat = DateFormat('HH:mm');
    tz.TZDateTime now = tz.TZDateTime.now(jakartaTimezone);
    DateTime prayerTime = timeFormat.parse(time);
    tz.TZDateTime scheduledDateTime = tz.TZDateTime(
      jakartaTimezone,
      now.year,
      now.month,
      now.day,
      prayerTime.hour,
      prayerTime.minute,
    );

    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = scheduledDateTime.add(Duration(days: 1)); // Schedule for next day if time has passed
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'prayer_channel',
      'Prayer Notifications',
      channelDescription: 'Notifications for prayer times',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      prayerName.hashCode, // Unique ID based on prayer name
      'Waktu $prayerName',
      'Sudah masuk waktu $prayerName!',
      scheduledDateTime,
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notifikasi untuk $prayerName telah diset')),
    );
  }

  // Helper to format time difference
  String _formatTimeDifference(Duration difference) {
    int hours = difference.inHours;
    int minutes = difference.inMinutes.remainder(60);
    String prefix = difference.isNegative ? '-' : '+';
    String timeStr = '';
    if (hours.abs() > 0) {
      timeStr += '${hours.abs()} jam ';
    }
    timeStr += '${minutes.abs()} menit';
    return '$prefix$timeStr ${difference.isNegative ? 'yang lalu' : 'akan datang'}';
  }

  // Get Isya status
  String _getIsyaStatus() {
    if (jadwal == null) return '';
    tz.TZDateTime now = tz.TZDateTime.now(jakartaTimezone);
    DateTime isyaTime = DateFormat('HH:mm').parse(jadwal!.isya);
    tz.TZDateTime todayIsyaTime = tz.TZDateTime(
      jakartaTimezone,
      now.year,
      now.month,
      now.day,
      isyaTime.hour,
      isyaTime.minute,
    );
    return todayIsyaTime.isBefore(now) ? 'Waktu Isya sudah lewat' : 'Akan masuk Waktu Isya';
  }

  // Get time difference from Isya
  String _getIsyaTimeDifference() {
    if (jadwal == null) return '';
    tz.TZDateTime now = tz.TZDateTime.now(jakartaTimezone);
    DateTime isyaTime = DateFormat('HH:mm').parse(jadwal!.isya);
    tz.TZDateTime todayIsyaTime = tz.TZDateTime(
      jakartaTimezone,
      now.year,
      now.month,
      now.day,
      isyaTime.hour,
      isyaTime.minute,
    );
    Duration difference = todayIsyaTime.difference(now);
    return _formatTimeDifference(difference);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jadwal Sholat'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : jadwal == null
            ? Center(child: Text('Memuat jadwal berdasarkan lokasi...', style: TextStyle(fontSize: 16)))
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Hijri and Gregorian dates
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tanggal Hijriah',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '1 Muharram 1446', // Replace with actual Hijri date API if available
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Tanggal Masehi',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      jadwal!.tanggal,
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            // Isya status and time difference
            if (jadwal != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _getIsyaStatus(),
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _getIsyaTimeDifference(),
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Lokasi: $selectedCity',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            SizedBox(height: 16),
            // Prayer times
            Expanded(
              child: ListView(
                children: [
                  PrayerTimeTile('Imsak', jadwal!.imsak, _scheduleNotification),
                  PrayerTimeTile('Subuh', jadwal!.subuh, _scheduleNotification),
                  PrayerTimeTile('Terbit', jadwal!.terbit, _scheduleNotification),
                  PrayerTimeTile('Dhuha', jadwal!.dhuha, _scheduleNotification),
                  PrayerTimeTile('Dzuhur', jadwal!.dzuhur, _scheduleNotification),
                  PrayerTimeTile('Ashar', jadwal!.ashar, _scheduleNotification),
                  PrayerTimeTile('Maghrib', jadwal!.maghrib, _scheduleNotification),
                  PrayerTimeTile('Isya', jadwal!.isya, _scheduleNotification),
                ],
              ),
            ),
            // Countdown to next prayer
            if (nextPrayerTime != null && timeUntilNextPrayer != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Menuju Waktu $nextPrayerName',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '+${timeUntilNextPrayer!.inMinutes} menit lagi',
                      style: TextStyle(fontSize: 16, color: Colors.green),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Widget for each prayer time with notification button
class PrayerTimeTile extends StatelessWidget {
  final String prayerName;
  final String time;
  final Function(String, String) onNotificationSet;

  PrayerTimeTile(this.prayerName, this.time, this.onNotificationSet);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        title: Text(prayerName, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(time),
        trailing: IconButton(
          icon: Icon(Icons.notifications, color: Colors.blue),
          onPressed: () => onNotificationSet(prayerName, time),
        ),
      ),
    );
  }
}