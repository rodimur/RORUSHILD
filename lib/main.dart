import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/network_analyzer_service.dart';
import 'services/notification_service.dart';
import 'data_usage_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Native platformlardan gelen hataları yakalama
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Hatası: ${details.exception}');
  };
  
  // Bildirim servisini başlat (sadece Android)
  try {
    await NotificationService.instance.initialize();
    debugPrint('Android bildirimleri başlatıldı');
  } catch (e) {
    debugPrint('Bildirim servisi başlatma hatası: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.light;
  static const MethodChannel _channel = MethodChannel('com.example.rorusheild2/vpn_channel');
  static const platform = MethodChannel('com.example.rorusheild2/accessibility');
  static const eventChannel = EventChannel('com.example.rorusheild2/url_events');
  final NetworkAnalyzerService _networkAnalyzer = NetworkAnalyzerService.instance;
  bool isServiceEnabled = false;

  @override
  void initState() {
    super.initState();
    _initializeMethodChannel();
    _checkAccessibilityPermission();
    _setupUrlListener();
    _networkAnalyzer.loadBlacklist();
  }

  void toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void _initializeMethodChannel() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'addDomain') {
        final domain = call.arguments as String;
        debugPrint("🔥 Flutter'a gelen domain: $domain");
        await _networkAnalyzer.addDomain(domain);
      } else if (call.method == 'vpnStatus') {
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

  Future<void> _checkAccessibilityPermission() async {
    try {
      final bool result = await platform.invokeMethod('checkAccessibilityPermission');
      setState(() {
        isServiceEnabled = result;
      });
    } catch (e) {
      print('Erişilebilirlik izni kontrolünde hata: $e');
    }
  }

  Future<void> _openAccessibilitySettings() async {
    try {
      await platform.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      print('Erişilebilirlik ayarları açılırken hata: $e');
    }
  }

  void _setupUrlListener() {
    eventChannel.receiveBroadcastStream().listen((dynamic event) async {
      if (event is Map) {
        final String url = event['url'] as String;
        debugPrint("📱 Yeni URL tespit edildi: $url");
        await _networkAnalyzer.addDomain(url);
      }
    }, onError: (dynamic error) {
      print('URL dinleme hatası: $error');
    });
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
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.grey[900],
        primaryColor: Colors.blue,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      themeMode: _themeMode,
      home: DataUsageScreen(toggleTheme: toggleTheme),
    );
  }
}
