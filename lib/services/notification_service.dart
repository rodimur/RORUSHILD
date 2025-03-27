import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  NotificationService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Android ayarları
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Başlangıç ayarları
      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      // Bildirimleri başlat
      await _notificationsPlugin.initialize(
        initializationSettings,
      );

      _isInitialized = true;
      debugPrint('Bildirim servisi başlatıldı');
    } catch (e) {
      debugPrint('Bildirim servisi başlatma hatası: $e');
    }
  }

  Future<void> showDangerousWebsiteNotification(String domainName) async {
    // Bildirim servisi başlatılmamışsa başlat
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Android detayları
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'dangerous_domains_channel',
        'Tehlikeli Websiteleri',
        channelDescription: 'Tehlikeli websiteler hakkında uyarılar',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        color: Colors.red,
        enableVibration: true,
      );

      // Platform ayarları
      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
      );

      // Bildirimi göster
      await _notificationsPlugin.show(
        0, // ID
        'Tehlikeli Website Uyarısı', // Başlık
        'Dikkat! $domainName tehlikeli bir websitedir. Lütfen dikkatli olun.', // İçerik
        notificationDetails,
      );

      debugPrint('Tehlikeli website bildirimi gönderildi: $domainName');
    } catch (e) {
      debugPrint('Bildirim gönderme hatası: $e');
    }
  }
} 