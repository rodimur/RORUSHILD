import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static final List<_GuideStep> steps = [
    _GuideStep(
      icon: Icons.bar_chart,
      title: 'Veri Kullanımınızı Anlık Takip Edin',
      desc: 'Uygulama, hangi uygulamanın ne kadar veri kullandığını detaylı grafiklerle gösterir. Aylık analizlerle internet harcamalarınızı kontrol altında tutun.',
    ),
    _GuideStep(
      icon: Icons.vpn_lock,
      title: 'VPN ile Güvende Kalın',
      desc: 'VPN özelliğini aktif ederek veri trafiğinizi şifreleyin,DNS sorgularını güvenli DNS sunucuları üzerinden gerçekleştirerek açık Wi-Fi ağlarında bile güvende kalın.',
    ),
    _GuideStep(
      icon: Icons.warning,
      title: 'Tehditleri Anında Tespit Edin',
      desc: 'Zararlı veya şüpheli sitelere erişimlerde otomatik uyarı alın. Tüm tehdit geçmişinizi görüntüleyin.',
    ),
    _GuideStep(
      icon: Icons.picture_as_pdf,
      title: 'Tehdit Analizi Raporu Oluşturun',
      desc: 'Tüm tehdit geçmişinizi PDF olarak dışa aktarın ve raporunuzu kolayca paylaşın.',
    ),
    _GuideStep(
      icon: Icons.backup,
      title: 'Veritabanı Yedekleme ve Geri Yükleme',
      desc: 'Menüden "Verileri Yedekle" ile veritabanınızı cihazınıza kaydedebilir, "Verileri Geri Yükle" ile önceden alınan yedeği tekrar yükleyebilirsiniz. Böylece verileriniz güvende ve taşınabilir olur.',
    ),
    _GuideStep(
      icon: Icons.notifications_active,
      title: 'Bildirimlerle Haberdar Olun',
      desc: 'Güvenlik için anlık bildirimler alın. Bildirim izinlerinizi kolayca yönetin.',
    ),
    _GuideStep(
      icon: Icons.settings,
      title: 'Kişiselleştirilebilir Ayarlar',
      desc: 'Tema seçimi ve bildirim tercihleriyle uygulamayı kendinize göre özelleştirin.',
    ),
    _GuideStep(
      icon: Icons.share,
      title: 'Geri Bildirim ve Paylaşım',
      desc: 'Uygulamayı arkadaşlarınızla paylaşın, görüşlerinizi geliştiriciye iletin.',
    ),
    _GuideStep(
      icon: Icons.help_outline,
      title: 'Yardım Kılavuzu',
      desc: 'Her özelliğin nasıl çalıştığını bu ekrandan öğrenin.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primary = isDark ? Colors.blue[200]! : Colors.blue;
    final Color bgColor = isDark ? const Color(0xFF10131A) : Colors.white;
    final Color cardColor = isDark ? const Color(0xFF1C2230) : Colors.white;
    final Color textColor = isDark ? Colors.blue[100]! : Colors.blue[800]!;
    final Color shadowColor = isDark ? Colors.black.withOpacity(0.45) : Colors.blue.withOpacity(0.18);
    final Color borderColor = isDark ? Colors.blueGrey.shade900 : Colors.blue.shade50;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Hızlı Başlangıç Kılavuzu", style: TextStyle(color: primary)),
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: primary),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: shadowColor,
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset(
                      'assets/icon/rorushieldicon.png',
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.shield, size: 90, color: primary),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  "Hoş Geldiniz!\nRoRü Shield'ın tüm özelliklerini aşağıdaki zaman çizgisinde keşfedin.",
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: textColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
          ...List.generate(steps.length, (i) => TimelineStepCard(
                step: steps[i],
                index: i,
                isLast: i == steps.length - 1,
                cardColor: cardColor,
                primary: primary,
                textColor: textColor,
                borderColor: borderColor,
              )),
        ],
      ),
    );
  }
}

class TimelineStepCard extends StatelessWidget {
  final _GuideStep step;
  final int index;
  final bool isLast;
  final Color cardColor;
  final Color primary;
  final Color textColor;
  final Color borderColor;
  const TimelineStepCard({
    required this.step,
    required this.index,
    required this.isLast,
    required this.cardColor,
    required this.primary,
    required this.textColor,
    required this.borderColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isLeft = index % 2 == 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline çizgisi ve nokta
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blue.shade200, width: 4),
              ),
              child: Icon(step.icon, color: Colors.white, size: 16),
            ),
            if (!isLast)
              Container(
                width: 4,
                height: 70,
                color: Colors.blue.shade200,
              ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Align(
            alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
            child: Container(
              margin: EdgeInsets.only(
                left: isLeft ? 8 : 40,
                right: isLeft ? 40 : 8,
                bottom: 28,
              ),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: primary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step.desc,
                    style: TextStyle(fontSize: 15, color: textColor.withOpacity(0.93)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GuideStep {
  final IconData icon;
  final String title;
  final String desc;
  const _GuideStep({required this.icon, required this.title, required this.desc});
}
