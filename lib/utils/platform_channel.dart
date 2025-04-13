import 'package:flutter/services.dart';

class PlatformChannel {
  // Android ile iletişim için kullanılan channel
  static const MethodChannel _channel = MethodChannel('com.example.rorusheild2/vpn_channel');

  // VPN başlatma komutunu Android tarafına gönderir
  static Future<void> startVpn() async {
    try {
      await _channel.invokeMethod('startVpn');
    } catch (e) {
      print("VPN Başlatma Hatası: $e");
    }
  }

  // VPN durdurma komutunu Android tarafına gönderir
  static Future<void> stopVpn() async {
    try {
      await _channel.invokeMethod('stopVpn');
    } catch (e) {
      print("VPN Durdurma Hatası: $e");
    }
  }
}
