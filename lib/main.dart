import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // MethodChannel için
import 'services/network_analyzer_service.dart'; // addDomain için
import 'data_usage_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  static const MethodChannel _channel = MethodChannel('com.example.rorusheild2/vpn_channel'); // Channel tanımı

  @override
  void initState() {
    super.initState();
    _initializeMethodChannel(); // Kanal dinlemesini başlat
  }

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  // Flutter MethodChannel dinlemesi
  void _initializeMethodChannel() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'addDomain') {
        final domain = call.arguments as String;
        debugPrint("🔥 Flutter'a gelen domain: $domain");
        NetworkAnalyzerService().addDomain(domain);
      } else if (call.method == 'vpnStatus') {  // VPN durumu
        final status = call.arguments as String;
        if (status == "active") {
          setState(() {
            // VPN aktif olduğunda ekranı güncelle
          });
        } else {
          setState(() {
            // VPN kapalı olduğunda ekranı güncelle
          });
        }
      }
    });
  }

  // VPN başlatma işlemi
  Future<void> startVpn() async {
    try {
      await _channel.invokeMethod('startVpn'); // VPN başlat
    } on PlatformException catch (e) {
      print("VPN başlatılırken hata: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RoRüShield',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.grey[100],
        primaryColor: Colors.blue,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.grey[900],
        primaryColor: Colors.blue,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      themeMode: _themeMode,
      home: DataUsageScreen(toggleTheme: toggleTheme),
    );
  }
}
