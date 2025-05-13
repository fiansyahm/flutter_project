import 'package:flutter/material.dart';
import 'db/adapters.dart';
import 'screens/splash_screen.dart';
import 'db/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.init(); // Initialize Hive
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Karen Cashier', // Use the hardcoded name from SplashScreen
      // theme: ThemeData(primarySwatch: Colors.yellow),
      home: SplashScreen(),
    );
  }
}