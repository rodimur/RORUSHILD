import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static const platform = MethodChannel('com.example.rorusheild2/accessibility');
  bool isServiceEnabled = false;
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkAccessibilityPermission();
  }

  Future<void> _checkAccessibilityPermission() async {
    try {
      final bool result = await platform.invokeMethod('checkAccessibilityPermission');
      setState(() {
        isServiceEnabled = result;
      });
      if (!result) {
        _showAccessibilityDialog();
      }
    } catch (e) {
      print('Erişilebilirlik izni kontrolünde hata: $e');
      setState(() {
        isServiceEnabled = false;
      });
    }
  }

  void _showAccessibilityDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Erişilebilirlik İzni Gerekli'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RoruShield\'ın çalışabilmesi için erişilebilirlik iznine ihtiyacı var.'),
              SizedBox(height: 8),
              Text('Ayarlar ekranında:'),
              Padding(
                padding: const EdgeInsets.only(left: 8.0, top: 4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('1. "Yüklenen Uygulamalar" altında "RoruShield"\'ı bulun'),
                    Text('2. "RoruShield" servisini etkinleştirin'),
                    Text('3. İzinleri onaylayın'),
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Daha Sonra'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Ayarlara Git'),
              onPressed: () async {
                Navigator.of(context).pop();
                await platform.invokeMethod('openAccessibilitySettings');
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sayfalar = [
      const CircularDataChart(),
      const VpnOff(),
      const UnsafeLogs(),
      const Logs(),
      MenuScreen(toggleTheme: widget.toggleTheme),
    ];

    return Scaffold(
      body: Column(
        children: [
          if (!isServiceEnabled)
            Container(
              padding: EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.error.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Theme.of(context).colorScheme.error),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Erişilebilirlik izni gerekli',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Web sitelerini izleyebilmek için RoruShield\'a erişilebilirlik izni vermeniz gerekiyor.',
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  SizedBox(height: 8),
                  Center(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.settings),
                      label: Text('Erişilebilirlik İznini Ver'),
                      onPressed: () async {
                        await platform.invokeMethod('openAccessibilitySettings');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: sayfalar[selectedIndex],
          ),
        ],
      ),
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
        backgroundColor: isDark ? Colors.grey[850] : Colors.white,
        selectedItemColor: const Color(0xFF1959E4),
        unselectedItemColor: isDark ? Colors.grey[500] : const Color(0xFFA3BDF5),
        onTap: (index) {
          setState(() {
            selectedIndex = index;
          });
        },
      ),
    );
  }
}
