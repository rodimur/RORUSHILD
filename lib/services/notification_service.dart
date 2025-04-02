import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // 👇 Kullanıcı bildirim izni burada tutuluyor
  bool notificationsAllowed = true;

  NotificationService._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

      final InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
      );

      _isInitialized = true;
      debugPrint('Bildirim servisi başlatıldı');
    } catch (e) {
      debugPrint('Bildirim servisi başlatma hatası: $e');
    }
  }

  // 👇 Sistem bildirim izinlerini kontrol et
  Future<bool> checkNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  // 👇 Sistem bildirim izinlerini iste
  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // 👇 Sistem bildirim izinlerini aç/kapat
  Future<void> toggleSystemNotifications(bool enable) async {
    if (enable) {
      // Bildirimleri aç
      await requestNotificationPermission();
    } else {
      // Bildirimleri kapat
      await openAppSettings();
    }
  }

  Future<void> showDangerousWebsiteNotification(String domainName) async {
    // 👇 Kullanıcı bildirim izni vermediyse hiçbir şey yapma
    if (!notificationsAllowed) {
      debugPrint("Kullanıcı bildirimleri devre dışı bıraktı, bildirim gönderilmedi.");
      return;
    }

    if (!_isInitialized) {
      await initialize();
    }

    try {
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

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
      );

      await _notificationsPlugin.show(
        0,
        'Tehlikeli Website Uyarısı',
        'Dikkat! $domainName tehlikeli bir websitedir. Lütfen dikkatli olun.',
        notificationDetails,
      );

      debugPrint('Tehlikeli website bildirimi gönderildi: $domainName');
    } catch (e) {
      debugPrint('Bildirim gönderme hatası: $e');
    }
  }
}
