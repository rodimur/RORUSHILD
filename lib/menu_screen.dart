import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rorusheild2/feedback_screen.dart';
import 'package:rorusheild2/help_screen.dart';
import 'package:rorusheild2/services/notification_service.dart';
import 'package:rorusheild2/services/pdf_report_service.dart';
import 'package:rorusheild2/share_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/services.dart';

class MenuScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  const MenuScreen({super.key, required this.toggleTheme});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with WidgetsBindingObserver {
  bool notificationsEnabled = true;
  static const platform = MethodChannel('com.example.rorusheild2/storage_permission');

  @override
  void initState() {
    super.initState();
    // 👇 Sayfa açıldığında mevcut bildirim durumunu yükle
    _loadNotificationState();
    // 👇 Uygulama durumu değişikliklerini dinle
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // 👇 Dinleyiciyi kaldır
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 👇 Uygulama ön plana geldiğinde bildirim durumunu kontrol et
    if (state == AppLifecycleState.resumed) {
      _loadNotificationState();
    }
  }

  // 👇 Bildirim durumunu yükle
  Future<void> _loadNotificationState() async {
    final hasPermission = await Permission.notification.status.isGranted;
    if (mounted) {  // 👇 Widget hala aktif mi kontrol et
      setState(() {
        notificationsEnabled = hasPermission;
        NotificationService.instance.notificationsAllowed = hasPermission;
      });
    }
  }

  Future<void> _downloadThreatReport() async {
    try {
      // Depolama izni kontrolü
      final status = await Permission.storage.status;
      if (status.isDenied) {
        final result = await Permission.storage.request();
        if (!result.isGranted) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Depolama İzni Gerekli'),
                  content: const Text(
                      'Rapor oluşturmak için depolama izni gereklidir. Lütfen ayarlardan izin verin.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        try {
                          await platform.invokeMethod('openStorageSettings');
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Ayarlar açılamadı: $e'),
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Ayarları Aç'),
                    ),
                  ],
                );
              },
            );
          }
          return;
        }
      }

      // Yükleniyor göstergesi
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rapor hazırlanıyor...')),
        );
      }

      // Raporu oluştur
      final path = await PdfReportService.instance.generateThreatReport();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rapor Download klasörüne kaydedildi: ${path.split('/').last}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata oluştu: $e')),
        );
      }
    }
  }

  // 👇 Sistem bildirim ayarlarına yönlendir
  Future<void> _openNotificationSettings() async {
    // Android'de uygulamanın kendi bildirim ayarlarını açmak için platform channel kullan
    if (Theme.of(context).platform == TargetPlatform.android) {
      const platform = MethodChannel('com.example.rorusheild2/notification_settings');
      try {
        await platform.invokeMethod('openNotificationSettings');
      } catch (e) {
        await openAppSettings(); // Yedek: genel ayarlara yönlendir
      }
    } else {
      await openAppSettings(); // iOS ve diğer platformlar
    }
  }

  Widget buildMenuItem(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white12 : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          leading: Icon(icon, color: Colors.blue),
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget buildNotificationToggle(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.white12 : Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
        ),
        child: ListTile(
          leading: const Icon(Icons.notifications_active, color: Colors.blue),
          title: Text(
            "Bildirimleri Aç/Kapat",
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          trailing: Switch(
            value: notificationsEnabled,
            onChanged: (value) async {
              // 👇 Sistem bildirim ayarlarına yönlendir
              await _openNotificationSettings();
              // 👇 Bildirim durumunu güncelle
              if (mounted) {  // 👇 Widget hala aktif mi kontrol et
                setState(() {
                  notificationsEnabled = value;
                  NotificationService.instance.notificationsAllowed = value;
                });
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "RoRü Shield",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.blue.shade800,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🔔 Bildirim Switch'i
                  buildNotificationToggle(context),

                  buildMenuItem(context, Icons.help_outline, "Yardım Kılavuzu", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HelpScreen()),
                    );
                  }),
                  buildMenuItem(context, Icons.share, "Uygulamayı Paylaş", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ShareScreen()),
                    );
                  }),
                  buildMenuItem(context, Icons.feedback_outlined, "Geribildirim Gönder", () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FeedbackScreen(),
                      ),
                    );
                  }),
                  buildMenuItem(context, Icons.analytics_outlined, "Tehdit Analizi Raporu", _downloadThreatReport),
                  const SizedBox(height: 10),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Light Mode Butonu
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        // Dark modda iken aktif, Light modda pasif
                        onPressed: isDark ? widget.toggleTheme : null,
                        child: Icon(
                          Icons.light_mode,
                          color: isDark ? Colors.black : Colors.grey.shade400,
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Dark Mode Butonu
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: !isDark ? Colors.blue : Colors.grey.shade400,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        // Light modda iken aktif, Dark modda pasif
                        onPressed: !isDark ? widget.toggleTheme : null,
                        child: Icon(
                          Icons.dark_mode,
                          color: !isDark ? Colors.blue : Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
