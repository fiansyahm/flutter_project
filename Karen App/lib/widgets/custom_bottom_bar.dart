import 'package:flutter/material.dart';
import '../screens/profile_screen.dart';
import '../screens/report_screen.dart';

class CustomBottomBar extends StatelessWidget {
  final VoidCallback onThemeToggle;
  final bool isGoldTheme;

  const CustomBottomBar({super.key, required this.onThemeToggle, required this.isGoldTheme});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
            icon: Icon(
              Icons.pie_chart,
              color: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReportScreen(
                    onThemeToggle: onThemeToggle,
                    isGoldTheme: isGoldTheme,
                  ),
                ),
              );
            },
            tooltip: 'Grafik',
          ),
          const SizedBox(width: 48),
          IconButton(
            icon: Icon(
              Icons.person,
              color: Theme.of(context).bottomNavigationBarTheme.selectedItemColor,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(
                    onThemeToggle: onThemeToggle,
                    isGoldTheme: isGoldTheme,
                  ),
                ),
              );
            },
            tooltip: 'Saya',
          ),
        ],
      ),
    );
  }
}