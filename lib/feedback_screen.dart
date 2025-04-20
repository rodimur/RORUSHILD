import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _sendFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final message = _controller.text.trim();
    final deviceInfo = await _getDeviceInfo();

    final email = Uri(
      scheme: 'mailto',
      path: 'rumeysakaya469@gmail.com',
      query: 'subject=RoRü Shield Geri Bildirim&body=$message\n\n\n$deviceInfo',
    );

    try {
      if (await canLaunchUrl(email)) {
        final launched = await launchUrl(email, mode: LaunchMode.externalApplication);
        if (!launched) {
          throw Exception('E-posta uygulaması açılamadı');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Geri bildiriminiz için teşekkürler!"),
              backgroundColor: Colors.green,
            ),
          );
          _controller.clear();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Lütfen cihazınızda bir e-posta uygulaması yükleyin."),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Hata: ${e.toString()}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String> _getDeviceInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String info = '';
    if (Platform.isAndroid) {
      final android = await deviceInfo.androidInfo;
      info = '''
Cihaz Bilgileri:
Cihaz Türü: Android
Marka: ${android.brand}
Model: ${android.model}
Android Sürümü: ${android.version.release} (SDK ${android.version.sdkInt})
Cihaz: ${android.device}
Üretici: ${android.manufacturer}
''';
    } else if (Platform.isIOS) {
      final ios = await deviceInfo.iosInfo;
      info = '''
Cihaz Türü: iOS
Model: ${ios.utsname.machine}
Sistem: ${ios.systemName} ${ios.systemVersion}
Cihaz Adı: ${ios.name}
''';
    } else {
      info = 'Bilinmeyen platform';
    }
    final now = DateTime.now();
    final formattedDate = "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    return '''
Gönderim Tarihi: $formattedDate
$info''';
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge!.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Geri Bildirim Gönder", style: TextStyle(color: Colors.blue)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.blue),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Uygulama hakkındaki düşüncelerinizi bizimle paylaşın.",
                style: TextStyle(fontSize: 16, color: textColor),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _controller,
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Lütfen bir geri bildirim yazın.";
                  }
                  if (value.trim().length < 10) {
                    return "Geri bildiriminiz en az 10 karakter olmalıdır.";
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: "Geri bildiriminizi buraya yazın...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.blue),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.blue),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _sendFeedback,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(_isLoading ? "Gönderiliyor..." : "Gönder"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
