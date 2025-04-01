import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';

class CircularDataChart extends StatefulWidget {
  const CircularDataChart({super.key});

  @override
  State<CircularDataChart> createState() => _CircularDataChartState();
}

class _CircularDataChartState extends State<CircularDataChart> {
  int selectedAppIndex = 0;
  // Uygulama kullanım verileri (getAppUsage ile)
  List<Map<String, dynamic>> apps = [];

  // Kategori verileri: Download, Upload, Wi‑Fi, Mobile
  final List<Map<String, dynamic>> categories = [
    {'name': 'Download', 'icon': Icons.download, 'usage': 0.0},
    {'name': 'Upload', 'icon': Icons.upload, 'usage': 0.0},
    {'name': 'Wi‑Fi', 'icon': Icons.wifi, 'usage': 0.0},
    {'name': 'Mobile', 'icon': Icons.cell_tower, 'usage': 0.0},
  ];

  static const MethodChannel _appUsageChannel =
  MethodChannel('com.example.rorusheild2/app_usage');
  static const MethodChannel _networkUsageChannel =
  MethodChannel('com.example.rorusheild2/network_usage');

  Timer? _usageTimer;

  @override
  void initState() {
    super.initState();
    _loadAppUsage();      // Uygulama bazlı verileri al
    _loadDetailedUsage(); // Kategori verilerini al: Download, Upload, Wi‑Fi, Mobile
    // Her 5 saniyede bir detaylı kullanım verilerini, her 15 saniyede bir uygulama verilerini güncelle
    _usageTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _loadDetailedUsage();
      // Her 15 saniyede bir uygulama kullanım verilerini güncelle
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
        apps = result.map((data) {
          return {
            'name': data['appName'],
            'usage': (data['usage'] as num).toDouble(),
            'icon': FontAwesomeIcons.mobileAlt,
            'color': Colors.blue,
          };
        }).toList();
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
      
      // Toplam download ve upload değerlerini doğrudan al
      final double totalRx = (result['totalRx'] as num).toDouble();
      final double totalTx = (result['totalTx'] as num).toDouble();
      final double wifiRx = (result['wifiRx'] as num).toDouble();
      final double wifiTx = (result['wifiTx'] as num).toDouble();
      final double mobileRx = (result['mobileRx'] as num).toDouble();
      final double mobileTx = (result['mobileTx'] as num).toDouble();

      setState(() {
        // Download: Toplam download verisi
        categories[0]['usage'] = totalRx;
        // Upload: Toplam upload verisi
        categories[1]['usage'] = totalTx;
        // Wi‑Fi toplam: rx + tx
        categories[2]['usage'] = wifiRx + wifiTx;
        // Mobile toplam: rx + tx
        categories[3]['usage'] = mobileRx + mobileTx;
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
                      segments: apps.map((app) => app['usage'] as double).toList(),
                      colors: apps.map((app) => app['color'] as Color).toList(),
                      selectedIndex: selectedAppIndex,
                    ),
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${apps[selectedAppIndex]['usage'].toStringAsFixed(2)}',
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
          // Kategori satırı: Download, Upload, Wi‑Fi, Mobile
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
                      color: selectedAppIndex == index
                          ? Colors.blue
                          : (isDark ? Colors.grey[800] : Colors.blue.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(
                        app['icon'] as IconData,
                        color: selectedAppIndex == index
                            ? Colors.white
                            : (isDark ? Colors.blue[300] : Colors.blue),
                      ),
                      title: Text(
                        app['name'] as String,
                        style: TextStyle(
                          color: selectedAppIndex == index
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black87),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Text(
                        '${(app['usage'] as double).toStringAsFixed(2)} GB',
                        style: TextStyle(
                          color: selectedAppIndex == index
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black87),
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
      ..strokeWidth = 25;

    double startAngle = -90 * (3.14159 / 180);
    final total = segments.reduce((a, b) => a + b);
    for (int i = 0; i < segments.length; i++) {
      final sweepAngle = (segments[i] / total) * 2 * 3.14159;
      paint.color = i == selectedIndex ? colors[i] : colors[i].withOpacity(0.3);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
