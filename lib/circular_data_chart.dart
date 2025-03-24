import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CircularDataChart extends StatefulWidget {
  const CircularDataChart({super.key});

  @override
  State<CircularDataChart> createState() => _CircularDataChartState();
}

class _CircularDataChartState extends State<CircularDataChart> {
  int selectedAppIndex = 0;
  
  final List<Map<String, dynamic>> apps = [
    {
      'name': 'YouTube',
      'icon': FontAwesomeIcons.youtube,
      'usage': 14.26,
      'color': Colors.blue,
    },
    {
      'name': 'Instagram',
      'icon': FontAwesomeIcons.instagram,
      'usage': 14.26,
      'color': Colors.blue.shade300,
    },
    {
      'name': 'Spotify',
      'icon': FontAwesomeIcons.spotify,
      'usage': 14.26,
      'color': Colors.blue.shade200,
    },
    {
      'name': 'Telegram',
      'icon': FontAwesomeIcons.telegram,
      'usage': 14.26,
      'color': Colors.blue.shade100,
    },
    {
      'name': 'LinkedIn',
      'icon': FontAwesomeIcons.linkedin,
      'usage': 14.26,
      'color': Colors.blue.shade50,
    },
  ];

  final List<Map<String, dynamic>> categories = [
    {'name': 'Mobil Veri', 'icon': Icons.cell_tower, 'usage': 24.01},
    {'name': 'Hotspot', 'icon': Icons.wifi_tethering, 'usage': 2.77},
    {'name': 'Wi-Fi', 'icon': Icons.wifi, 'usage': 18.10},
    {'name': 'Uygulama', 'icon': Icons.phone_android, 'usage': 8.68},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
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
                      '${apps[selectedAppIndex]['usage']}',
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
            children: categories
                .map(
                  (category) => Column(
                    children: [
                      Icon(category['icon'] as IconData, color: Colors.blue),
                      const SizedBox(height: 4),
                      Text(
                        '${category['usage']} GB',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
                .toList(),
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
                          : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Icon(
                        app['icon'] as IconData,
                        color: selectedAppIndex == index ? Colors.white : Colors.blue,
                      ),
                      title: Text(
                        app['name'] as String,
                        style: TextStyle(
                          color: selectedAppIndex == index ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Text(
                        '${app['usage']} GB',
                        style: TextStyle(
                          color: selectedAppIndex == index ? Colors.white : Colors.black87,
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
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 25;

    double startAngle = -90 * (3.14159 / 180); // Start from top
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
