import 'package:flutter/services.dart';

class DataUsageService {
  static const platform = MethodChannel('com.rorusheild/data');

  static Future<Map<String, double>> getDataUsage() async {
    try {
      final Map result = await platform.invokeMethod('getDataUsage');
      return Map<String, double>.from(
        result.map((key, value) => MapEntry(key, (value as int) / (1024 * 1024 * 1024))), // byte -> GB
      );
    } catch (e) {
      print("Veri kullanımı alınamadı: $e");
      return {};
    }
  }
}
