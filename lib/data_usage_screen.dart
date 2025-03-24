import 'package:flutter/material.dart';
import 'circular_data_chart.dart';
import 'vpn_off.dart';
import 'unsafe_logs.dart';
import 'logs.dart';
import 'menu_screen.dart';

class DataUsageScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  const DataUsageScreen({super.key, required this.toggleTheme});

  @override
  State<DataUsageScreen> createState() => _DataUsageScreenState();
}

class _DataUsageScreenState extends State<DataUsageScreen> {
  int selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final sayfalar = [
      const CircularDataChart(),
      const VpnOff(),
      const UnsafeLogs(),
      const Logs(),
      MenuScreen(toggleTheme: widget.toggleTheme),
    ];

    return Scaffold(
      body: sayfalar[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.insert_chart_outlined_outlined),
            label: " ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shield_moon_outlined),
            label: " ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.remove_circle_outline_rounded),
            label: " ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_rounded),
            label: " ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: " ",
          ),
        ],
        currentIndex: selectedIndex,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF1959E4),
        unselectedItemColor: const Color(0xFFA3BDF5),
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
      ),
    );
  }
}
