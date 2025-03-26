import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

class VisitedDomain {
  final String url;
  final DateTime timestamp;

  VisitedDomain({required this.url, required this.timestamp});
}

class NetworkAnalyzerService {
  static final NetworkAnalyzerService _instance = NetworkAnalyzerService._internal();
  factory NetworkAnalyzerService() => _instance;
  NetworkAnalyzerService._internal() {
    _loadBlacklist(); // Servis oluşturulunca blacklist’i oku
  }

  final List<VisitedDomain> _visitedDomains = [];
  final List<VisitedDomain> _dangerousDomains = [];

  final _domainController = StreamController<List<VisitedDomain>>.broadcast();
  final _dangerousController = StreamController<List<VisitedDomain>>.broadcast();

  bool _isAnalyzing = false;
  Timer? _analysisTimer;

  static const int _maxDomains = 1000;
  static const Duration _analysisInterval = Duration(seconds: 2);

  List<String> _blacklist = [];

  Stream<List<VisitedDomain>> get visitedDomainsStream => _domainController.stream;
  Stream<List<VisitedDomain>> get dangerousDomainsStream => _dangerousController.stream;

  List<VisitedDomain> get visitedDomains => List.unmodifiable(_visitedDomains);
  List<VisitedDomain> get dangerousDomains => List.unmodifiable(_dangerousDomains);

  Future<void> _loadBlacklist() async {
    try {
      final data = await rootBundle.loadString('assets/blacklist.txt');
      _blacklist = data.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      debugPrint("🛡️ Blacklist yüklendi: ${_blacklist.length} domain");
    } catch (e) {
      debugPrint("❌ Blacklist yüklenirken hata: $e");
    }
  }

  void startAnalyzing() {
    if (_isAnalyzing) return;
    _isAnalyzing = true;
    _analyzeNetworkTraffic();
  }

  void stopAnalyzing() {
    _isAnalyzing = false;
    _analysisTimer?.cancel();
    _analysisTimer = null;
  }

  void _analyzeNetworkTraffic() {
    _analysisTimer?.cancel();
    _analysisTimer = Timer.periodic(_analysisInterval, (timer) {
      if (!_isAnalyzing) {
        timer.cancel();
        return;
      }

      // Simülasyon verisi kaldırıldı, artık gerçek ağ verisi üzerinden işlem yapılacak.
      // Artık sadece gelen domainler işleniyor
    });
  }

  void addDomain(String domainName) {
    try {
      final domain = VisitedDomain(
        url: domainName,
        timestamp: DateTime.now(),
      );

      if (_visitedDomains.length >= _maxDomains) {
        _visitedDomains.removeAt(0);
      }

      _visitedDomains.add(domain);
      _domainController.add(List.from(_visitedDomains));

      if (_blacklist.any((b) => domainName.contains(b))) {
        _dangerousDomains.add(domain);
        _dangerousController.add(List.from(_dangerousDomains));
      }

    } catch (e) {
      debugPrint('⚠️ Domain eklenirken hata oluştu: $e');
    }
  }

  void clearDomains() {
    _visitedDomains.clear();
    _dangerousDomains.clear();
    _domainController.add(_visitedDomains);
    _dangerousController.add(_dangerousDomains);
  }

  void dispose() {
    stopAnalyzing();
    _domainController.close();
    _dangerousController.close();
  }
}
