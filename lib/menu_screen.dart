import 'package:flutter/material.dart';
import 'package:rorusheild2/feedback_screen.dart';
import 'package:rorusheild2/help_screen.dart';
import 'package:rorusheild2/services/notification_service.dart';
import 'package:rorusheild2/share_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class MenuScreen extends StatefulWidget {
  final VoidCallback toggleTheme;

  const MenuScreen({super.key, required this.toggleTheme});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with WidgetsBindingObserver {
  bool notificationsEnabled = true;

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

  // 👇 Sistem bildirim ayarlarına yönlendir
  Future<void> _openNotificationSettings() async {
    await openAppSettings();
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
              buildMenuItem(context, Icons.feedback_outlined, "Geri Bildirim Gönder", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const FeedbackScreen()),
                );
              }),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.white : Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: widget.toggleTheme,
                    child: Icon(Icons.light_mode,
                        color: isDark ? Colors.black : Colors.white),
                  ),
                  const SizedBox(width: 20),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.blue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: widget.toggleTheme,
                    child: const Icon(Icons.dark_mode, color: Colors.blue),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
