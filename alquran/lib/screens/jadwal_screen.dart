import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
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

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones(); // Initialize timezone database
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

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      String cityId = await _getCityIdFromCoordinates(position.latitude, position.longitude);
      Jadwal result = await jadwalService.getJadwal(cityId);
      setState(() {
        jadwal = result;
        selectedCity = 'Lokasi Anda';
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

  // Dummy function to get city ID from coordinates (replace with actual API call if needed)
  Future<String> _getCityIdFromCoordinates(double lat, double lon) async {
    // For simplicity, we'll assume a fixed city ID (e.g., Jakarta: 1301).
    // In a real app, use a reverse geocoding API (e.g., Google Maps Geocoding API) to get the city.
    return '1301'; // Jakarta's ID from the API you’re using
  }

  // Start countdown for next prayer
  void _startPrayerCountdown() {
    Future.delayed(Duration(seconds: 1), () {
      if (jadwal != null) {
        DateTime now = DateTime.now();
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
          DateTime todayPrayerTime = DateTime(now.year, now.month, now.day, prayerTime.hour, prayerTime.minute);
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
    DateTime now = DateTime.now();
    DateTime prayerTime = timeFormat.parse(time);
    DateTime scheduledDateTime = DateTime(now.year, now.month, now.day, prayerTime.hour, prayerTime.minute);

    if (scheduledDateTime.isBefore(now)) {
      scheduledDateTime = scheduledDateTime.add(Duration(days: 1)); // Schedule for next day if time has passed
    }

    // Convert DateTime to TZDateTime using the local timezone
    final tz.TZDateTime scheduledTime = tz.TZDateTime.from(scheduledDateTime, tz.local);

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
      scheduledTime,
      notificationDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Notifikasi untuk $prayerName telah diset')),
    );
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