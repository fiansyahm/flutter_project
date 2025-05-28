import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'db/database_helper.dart';
import 'screens/splash_screen.dart'; // Updated to use SplashScreen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper().initHive();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Karen Family',
      theme: ThemeData(primarySwatch: Colors.yellow),
      home: const SplashScreen(), // Changed to SplashScreen
    );
  }
}