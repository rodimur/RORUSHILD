import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import '../models/visited_domain.dart';
import 'database_service.dart';
import 'notification_service.dart';

class NetworkAnalyzerService {
  static final NetworkAnalyzerService _instance = NetworkAnalyzerService._internal();
  static NetworkAnalyzerService get instance => _instance;

  NetworkAnalyzerService._internal();

  final StreamController<List<VisitedDomain>> _visitedDomainsController = StreamController<List<VisitedDomain>>.broadcast();
  final StreamController<List<VisitedDomain>> _dangerousDomainsController = StreamController<List<VisitedDomain>>.broadcast();

  Stream<List<VisitedDomain>> get visitedDomainsStream => _visitedDomainsController.stream;
  Stream<List<VisitedDomain>> get dangerousDomainsStream => _dangerousDomainsController.stream;

  List<VisitedDomain> _visitedDomains = [];
  List<VisitedDomain> _dangerousDomains = [];
  List<String> _blacklist = [];
  bool _isAnalyzing = false;
  final DatabaseService _dbService = DatabaseService.instance;
  
  // Son işlenen URL'yi ve işlem zamanını saklayacak değişkenler
  String _lastProcessedUrl = '';
  DateTime? _lastProcessedTime;

  bool get isVpnActive => _isAnalyzing;

  Future<void> loadBlacklist() async {
    try {
      final String data = await rootBundle.loadString('assets/blacklist.txt');
      _blacklist = LineSplitter.split(data)
          .map((line) => line.trim().toLowerCase())
          .where((line) => line.isNotEmpty)
          .toList();
      debugPrint('📋 Blacklist yüklendi: ${_blacklist.length} domain');
      
      // Veritabanındaki domainleri yükle
      await _loadDomainsFromDatabase();
    } catch (e) {
      debugPrint('❌ Blacklist yüklenirken hata: $e');
      _blacklist = [];
    }
  }

  Future<void> _loadDomainsFromDatabase() async {
    try {
      // Güvenli domainleri veritabanından yükle
      final safeDomains = await _dbService.getSafeDomains();
      _visitedDomains = safeDomains;
      _visitedDomainsController.add(_visitedDomains);
      
      // Tehlikeli domainleri veritabanından yükle
      final unsafeDomains = await _dbService.getUnsafeDomains();
      _dangerousDomains = unsafeDomains;
      _dangerousDomainsController.add(_dangerousDomains);
      
      debugPrint('📂 Veritabanından ${safeDomains.length} güvenli, ${unsafeDomains.length} tehlikeli domain yüklendi');
    } catch (e) {
      debugPrint('❌ Veritabanından domainler yüklenirken hata: $e');
    }
  }

  bool _isUrlInBlacklist(String url) {
    try {
      final uri = Uri.parse(url.toLowerCase());
      final domain = uri.host;
      final path = uri.path;
      
      debugPrint('🔍 URL kontrol ediliyor: $url');
      debugPrint('📌 Domain: $domain');
      debugPrint('📌 Path: $path');
      
      for (final pattern in _blacklist) {
        if (domain.contains(pattern) || pattern.contains(domain)) {
          debugPrint('⚠️ Tehlikeli domain tespit edildi: $pattern');
          return true;
        }
      }
      
      debugPrint('✅ Domain güvenli');
      return false;
    } catch (e) {
      debugPrint('❌ URL kontrol edilirken hata: $e');
      return false;
    }
  }

  Future<void> addDomain(String url) async {
    if (url.isEmpty) return;

    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || !uri.host.contains('.')) return;
      
      // Eğer aynı URL son 15 saniye içinde işlendiyse tekrar işleme
      final now = DateTime.now();
      if (url == _lastProcessedUrl && _lastProcessedTime != null && 
          now.difference(_lastProcessedTime!).inSeconds < 15) {
        debugPrint('⏱️ Aynı URL son 15 saniye içinde işlendiği için atlanıyor: $url');
        return;
      }
      
      // İşlenen URL ve zamanını güncelle
      _lastProcessedUrl = url;
      _lastProcessedTime = now;
      
      final isSafe = !_isUrlInBlacklist(url);
      final domain = uri.host;
      final path = uri.path;
      
      final visitedDomain = VisitedDomain(
        url: url,
        domain: domain,
        path: path,
        timestamp: now,
        isSafe: isSafe,
      );

      // Veritabanına kaydet
      await _dbService.addVisitedDomain(visitedDomain);

      if (!isSafe) {
        // Tehlikeli alan - her zaman ekle
        _dangerousDomains.add(visitedDomain);
        _dangerousDomainsController.add(_dangerousDomains);
        debugPrint('⚠️ Tehlikeli domain tespit edildi: $url');
        
        // Tehlikeli domain bildirimini gönder
        await NotificationService.instance.showDangerousWebsiteNotification(domain);
      } else {
        // Güvenli alan - her zaman ekle
        _visitedDomains.add(visitedDomain);
        _visitedDomainsController.add(_visitedDomains);
        debugPrint('✅ Yeni domain eklendi: $url');
      }
    } catch (e) {
      debugPrint('❌ Domain eklenirken hata: $e');
    }
  }

  void startAnalyzing() {
    _isAnalyzing = true;
  }

  void stopAnalyzing() {
    _isAnalyzing = false;
  }

  void clearDomains() {
    _visitedDomains.clear();
    _dangerousDomains.clear();
    _visitedDomainsController.add(_visitedDomains);
    _dangerousDomainsController.add(_dangerousDomains);
    debugPrint('🧹 Tüm domainler temizlendi');
  }

  void dispose() {
    _visitedDomainsController.close();
    _dangerousDomainsController.close();
  }
}
