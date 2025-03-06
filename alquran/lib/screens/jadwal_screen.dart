import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:convert';
import 'dart:math'; // For Qibla direction calculation
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
  double? qiblaDirection;
  Position? currentPosition;

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
      currentPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      _calculateQiblaDirection(currentPosition!.latitude, currentPosition!.longitude);
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

  // Start countdown for next prayer and update nearest prayer status
  void _startPrayerCountdown() {
    Future.delayed(Duration(seconds: 1), () {
      if (jadwal != null) {
        tz.TZDateTime now = tz.TZDateTime.now(jakartaTimezone);
        List<Map<String, dynamic>> prayerTimes = [
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
        tz.TZDateTime? lastPrayerTime;
        String? lastPrayerName;

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
          } else {
            lastPrayerTime = todayPrayerTime;
            lastPrayerName = prayer['name']!;
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
      scheduledDateTime = scheduledDateTime.add(Duration(days: 1)); // Schedule for next day
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
      prayerName.hashCode,
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

  // Get nearest prayer status
  String _getNearestPrayerStatus() {
    if (jadwal == null) return '';
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
    tz.TZDateTime? lastPrayerTime;
    String? lastPrayerName;
    tz.TZDateTime? nextPrayerTimeLocal;
    String? nextPrayerNameLocal;

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
        nextPrayerTimeLocal = todayPrayerTime;
        nextPrayerNameLocal = prayer['name']!;
        break;
      } else {
        lastPrayerTime = todayPrayerTime;
        lastPrayerName = prayer['name']!;
      }
    }

    if (nextPrayerTimeLocal != null) {
      return 'Akan masuk Waktu $nextPrayerNameLocal';
    } else if (lastPrayerTime != null) {
      return 'Waktu $lastPrayerName sudah lewat';
    }
    return 'Tidak ada jadwal hari ini';
  }

  // Get time difference from nearest prayer
  String _getNearestPrayerTimeDifference() {
    if (jadwal == null) return '';
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
    tz.TZDateTime? lastPrayerTime;
    tz.TZDateTime? nextPrayerTimeLocal;

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
        nextPrayerTimeLocal = todayPrayerTime;
        break;
      } else {
        lastPrayerTime = todayPrayerTime;
      }
    }

    Duration difference;
    if (nextPrayerTimeLocal != null) {
      difference = nextPrayerTimeLocal.difference(now);
    } else if (lastPrayerTime != null) {
      difference = lastPrayerTime.difference(now);
    } else {
      return '';
    }
    return _formatTimeDifference(difference);
  }

  // Calculate Qibla direction
  void _calculateQiblaDirection(double lat, double lon) {
    const double kaabaLat = 21.4225; // Latitude of Kaaba
    const double kaabaLon = 39.8262; // Longitude of Kaaba

    double lat1 = lat * pi / 180; // Convert to radians
    double lon1 = lon * pi / 180;
    double lat2 = kaabaLat * pi / 180;
    double lon2 = kaabaLon * pi / 180;

    double dLon = lon2 - lon1;
    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    double bearing = atan2(y, x);

    bearing = bearing * 180 / pi; // Convert back to degrees
    bearing = (bearing + 360) % 360; // Normalize to 0-360 degrees

    setState(() {
      qiblaDirection = bearing;
    });
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
            // Nearest prayer status and time difference
            if (jadwal != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    _getNearestPrayerStatus(),
                    style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _getNearestPrayerTimeDifference(),
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Lokasi: $selectedCity',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    qiblaDirection != null
                        ? 'Arah Kiblat: ${qiblaDirection!.toStringAsFixed(1)}° dari Utara'
                        : 'Menghitung arah Kiblat...',
                    style: TextStyle(fontSize: 14, color: Colors.blue),
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