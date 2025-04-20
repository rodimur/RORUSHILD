import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';

class AppData {
  final String name;
  final double usage;
  final String? iconBase64;
  final String packageName;

  AppData({
    required this.name,
    required this.usage,
    this.iconBase64,
    required this.packageName,
  });

  factory AppData.fromMap(Map<dynamic, dynamic> map) {
    return AppData(
      name: map['appName']?.toString() ?? 'Unknown App',
      usage: (map['usage'] as num?)?.toDouble() ?? 0.0,
      iconBase64: map['icon']?.toString(),
      packageName: map['packageName']?.toString() ?? '',
    );
  }
}

class CircularDataChart extends StatefulWidget {
  const CircularDataChart({super.key});

  @override
  State<CircularDataChart> createState() => _CircularDataChartState();
}

class _CircularDataChartState extends State<CircularDataChart> {
  int selectedAppIndex = 0;
  List<AppData> apps = [];

  final List<Map<String, dynamic>> categories = [
    {'name': 'Toplam Download', 'icon': Icons.download, 'usage': 0.0},
    {'name': 'Toplam Upload', 'icon': Icons.upload, 'usage': 0.0},
    {'name': 'Toplam Wi‑Fi', 'icon': Icons.wifi, 'usage': 0.0},
    {'name': 'Toplam Mobile', 'icon': Icons.cell_tower, 'usage': 0.0},
  ];

  static const MethodChannel _appUsageChannel =
  MethodChannel('com.example.rorusheild2/app_usage');
  static const MethodChannel _networkUsageChannel =
  MethodChannel('com.example.rorusheild2/network_usage');

  Timer? _usageTimer;

  @override
  void initState() {
    super.initState();
    _loadAppUsage();
    _loadDetailedUsage();
    _usageTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _loadDetailedUsage();
      if (timer.tick % 3 == 0) {
        _loadAppUsage();
      }
    });
  }

  Future<void> _loadAppUsage() async {
    if (!mounted) return;
    try {
      final List<dynamic> result =
      await _appUsageChannel.invokeMethod('getAppUsage');
      setState(() {
        apps = result.map((data) => AppData.fromMap(data as Map<dynamic, dynamic>)).toList();
        selectedAppIndex = apps.isNotEmpty ? 0 : 0;
      });
    } catch (e) {
      print("App usage verileri yüklenirken hata: $e");
    }
  }

  Future<void> _loadDetailedUsage() async {
    if (!mounted) return;
    try {
      final Map<dynamic, dynamic> result =
      await _networkUsageChannel.invokeMethod('getDetailedNetworkUsage');

      // Kotlin tarafından gönderilen toplam değerleri al
      final double totalRx = (result['totalRx'] as num).toDouble();
      final double totalTx = (result['totalTx'] as num).toDouble();
      final double totalWifi = result.containsKey('totalWifi') ? (result['totalWifi'] as num).toDouble() : 0.0;
      final double totalMobile = result.containsKey('totalMobile') ? (result['totalMobile'] as num).toDouble() : 0.0;

      // Uygulamaların toplam kullanımını hesapla
      double totalAppUsage = 0.0;
      for (var app in apps) {
        totalAppUsage += app.usage;
      }

      setState(() {
        // Kategorileri gerçek toplam değerlerle güncelle
        categories[0]['usage'] = totalRx;       // Toplam Download
        categories[1]['usage'] = totalTx;       // Toplam Upload
        categories[2]['usage'] = totalWifi;     // Toplam Wi-Fi
        categories[3]['usage'] = totalMobile;   // Toplam Mobile
      });
    } catch (e) {
      print("Detaylı network verisi alınırken hata: $e");
    }
  }

  @override
  void dispose() {
    _usageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      body: apps.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          const SizedBox(height: 60),
          SizedBox(
            height: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 240,
                  height: 240,
                  child: CustomPaint(
                    painter: CircularChartPainter(
                      segments: [...apps.map((e) => e.usage)],
                      colors: [...apps.map((e) => Colors.blue)],
                      selectedIndex: selectedAppIndex,
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${apps[selectedAppIndex].usage.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const Text(
                      'GB',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: categories.map((category) {
              return Column(
                children: [
                  Icon(category['icon'] as IconData, color: Colors.blue),
                  const SizedBox(height: 4),
                  Text(
                    '${(category['usage'] as double).toStringAsFixed(2)} GB',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: apps.length,
              itemBuilder: (context, index) {
                final app = apps[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedAppIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: selectedAppIndex == index
                            ? [Colors.blue[900]!, Colors.blue[600]!]
                            : [
                          Color.lerp(Colors.blue[900], Colors.blue[300], index / apps.length)!,
                          Color.lerp(Colors.blue[700], Colors.blue[100], index / apps.length)!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: app.iconBase64 != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(
                          base64Decode(app.iconBase64!),
                          width: 32,
                          height: 32,
                        ),
                      )
                          : Icon(
                        FontAwesomeIcons.mobileAlt,
                        color: selectedAppIndex == index ? Colors.white : Colors.blue[900],
                      ),
                      title: Text(
                        app.name,
                        style: TextStyle(
                          color: selectedAppIndex == index ? Colors.white : (isDark ? Colors.white : Colors.blue[900]),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Text(
                        '${app.usage.toStringAsFixed(2)} GB',
                        style: TextStyle(
                          color: selectedAppIndex == index ? Colors.white : (isDark ? Colors.white70 : Colors.blue[800]),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CircularChartPainter extends CustomPainter {
  final List<double> segments;
  final List<Color> colors;
  final int selectedIndex;

  CircularChartPainter({
    required this.segments,
    required this.colors,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt
      ..strokeWidth = 25;

    double currentAngle = -90 * (3.14159 / 180);
    final total = segments.reduce((a, b) => a + b);

    List<double> rotatedSegments = [...segments.sublist(selectedIndex), ...segments.sublist(0, selectedIndex)];
    List<Color> rotatedColors = [...colors.sublist(selectedIndex), ...colors.sublist(0, selectedIndex)];

    for (int i = 0; i < rotatedSegments.length; i++) {
      final sweepAngle = (rotatedSegments[i] / total) * 2 * 3.14159;
      paint.color = (i == 0) ? rotatedColors[i] : rotatedColors[i].withOpacity(0.1);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        currentAngle,
        sweepAngle,
        false,
        paint,
      );
      currentAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
