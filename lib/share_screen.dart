import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ShareScreen extends StatelessWidget {
  const ShareScreen({super.key});

  void shareApp(BuildContext context) {
    final message = '''
RoRü Shield ile ağını koru! 🛡️📱

Cihazındaki internet trafiğini analiz et, zararlı sitelere karşı korun.

Uygulama şu anda sadece özel APK olarak kullanılmaktadır. Denemek istersen benimle iletişime geç! 💬
''';

    Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge!.color;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Uygulamayı Paylaş", style: TextStyle(color: Colors.blue)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.blue),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.shield, size: 80, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              "RoRü Shield ile ağını koru!",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Cihazındaki internet trafiğini analiz et, veri kullanımını kontrol altına al, zararlı sitelere karşı kendini koru.",
              style: TextStyle(fontSize: 16, color: textColor),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => shareApp(context),
              icon: const Icon(Icons.share),
              label: const Text("Uygulamayı Paylaş"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                textStyle: const TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const Spacer(),
            Text(
              "Paylaşarak sevdiklerini de korumalarına yardım et! 💙",
              style: TextStyle(color: textColor, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
