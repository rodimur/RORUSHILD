import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class NetworkUsageService {
  static const platform = MethodChannel('com.example.rorusheild2/network_usage');
  static Timer? _permissionCheckTimer;
  static bool _isCheckingPermission = false;
  
  static Future<bool> checkAndRequestPermissions() async {
    if (_isCheckingPermission) {
      return false;
    }

    try {
      _isCheckingPermission = true;
      debugPrint('İzin kontrolü başlatılıyor...');
      
      bool hasPermission = await platform.invokeMethod('checkUsagePermission');
      debugPrint('Mevcut izin durumu: $hasPermission');
      
      if (!hasPermission) {
        debugPrint('İzin yok, izin isteme başlatılıyor...');
        try {
          final result = await platform.invokeMethod('requestUsagePermission');
          debugPrint('İzin isteme sonucu: $result');
          
          await Future.delayed(const Duration(seconds: 1));
          hasPermission = await platform.invokeMethod('checkUsagePermission');
          debugPrint('İzin durumu güncellendi: $hasPermission');
          
          if (!hasPermission) {
            await Future.delayed(const Duration(seconds: 1));
            hasPermission = await platform.invokeMethod('checkUsagePermission');
            debugPrint('Son izin kontrolü: $hasPermission');
          }
        } catch (e) {
          debugPrint('İzin isteme hatası: $e');
          _isCheckingPermission = false;
          return false;
        }
      }
      
      _isCheckingPermission = false;
      return hasPermission;
    } catch (e) {
      debugPrint('İzin kontrolü başarısız: $e');
      _isCheckingPermission = false;
      return false;
    }
  }

  static Future<Map<String, double>> getRealTimeNetworkStats() async {
    try {
      debugPrint('Gerçek zamanlı ağ istatistikleri alınıyor...');
      
      bool hasPermission = await checkAndRequestPermissions();
      
      if (!hasPermission) {
        debugPrint('Kullanım erişimi izni verilmedi!');
        return {'mobileData': 0, 'wifiData': 0, 'totalData': 0};
      }

      debugPrint('İzin var, veriler alınıyor...');
      final Map<dynamic, dynamic>? result = await platform.invokeMethod('getTotalNetworkUsage');
      
      if (result == null) {
        debugPrint('Veri alınamadı: result null');
        return {'mobileData': 0, 'wifiData': 0, 'totalData': 0};
      }
      
      double mobileData = _convertToGB(result['mobileData']);
      double wifiData = _convertToGB(result['wifiData']);
      double totalData = _convertToGB(result['totalData']);
      
      debugPrint('Ham veriler:');
      debugPrint('Mobile: ${result['mobileData']} bytes');
      debugPrint('WiFi: ${result['wifiData']} bytes');
      debugPrint('Total: ${result['totalData']} bytes');
      
      debugPrint('Dönüştürülmüş veriler:');
      debugPrint('Mobile: ${mobileData.toStringAsFixed(2)} GB');
      debugPrint('WiFi: ${wifiData.toStringAsFixed(2)} GB');
      debugPrint('Total: ${totalData.toStringAsFixed(2)} GB');
      
      return {
        'mobileData': double.parse(mobileData.toStringAsFixed(2)),
        'wifiData': double.parse(wifiData.toStringAsFixed(2)),
        'totalData': double.parse(totalData.toStringAsFixed(2))
      };
    } catch (e) {
      debugPrint('Network stats alınamadı: $e');
      return {'mobileData': 0, 'wifiData': 0, 'totalData': 0};
    }
  }

  static double _convertToGB(dynamic bytes) {
    if (bytes == null) return 0.0;
    return (bytes as int) / (1024 * 1024 * 1024);
  }

  static void dispose() {
    _permissionCheckTimer?.cancel();
    _permissionCheckTimer = null;
  }
} 