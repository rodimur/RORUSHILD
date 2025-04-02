import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyLarge!.color);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Yardım Kılavuzu", style: TextStyle(color: Colors.blue)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.blue),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            "RoRü Shield Nedir?",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 10),
          Text(
            "RoRü Shield, mobil cihazınızda çalışan ağ trafiğini analiz eder, veri kullanımınızı izler ve zararlı sitelere karşı sizi uyarır.",
            style: textStyle,
          ),
          const SizedBox(height: 20),

          Text(
            "Uygulama Ekranları:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 10),
          helpItem("📊 Veri Kullanımı", "Telefonunuzda yüklü uygulamaların ne kadar internet kullandığını gösterir."),
          helpItem("🛡️ VPN", "VPN bağlantısını aktif ederek güvenli gezinme sağlar."),
          helpItem("⚠️ Tehdit Tespiti", "Zararlı web siteleri ziyaret edildiğinde sizi uyarır ve kayıt altına alır."),
          helpItem("📜 Loglar", "Geçmişte ziyaret edilen sitelerin listesini tutar."),
          helpItem("⚙️ Ayarlar", "Tema, veri limiti ve bildirim seçeneklerini düzenleyebileceğiniz alan."),
        ],
      ),
    );
  }

  Widget helpItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(desc),
          const Divider(),
        ],
      ),
    );
  }
}
