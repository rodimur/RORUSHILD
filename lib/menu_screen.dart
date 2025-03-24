import 'package:flutter/material.dart';

class MenuScreen extends StatelessWidget {
  final VoidCallback toggleTheme;

  const MenuScreen({super.key, required this.toggleTheme});

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
              buildMenuItem(context, Icons.settings, "Ayarlar", () {}),
              buildMenuItem(context, Icons.help_outline, "Yardım Kılavuzu", () {}),
              buildMenuItem(context, Icons.share, "Uygulamayı Paylaş", () {}),
              buildMenuItem(context, Icons.feedback_outlined, "Geri Bildirim Gönder", () {}),
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
                    onPressed: toggleTheme,
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
                    onPressed: toggleTheme,
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
