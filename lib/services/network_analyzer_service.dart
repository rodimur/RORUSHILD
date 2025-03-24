import 'dart:async';
import 'package:flutter/foundation.dart';

class VisitedDomain {
  final String url;
  final DateTime timestamp;

  VisitedDomain({required this.url, required this.timestamp});
}

class NetworkAnalyzerService {
  static final NetworkAnalyzerService _instance = NetworkAnalyzerService._internal();
  factory NetworkAnalyzerService() => _instance;
  NetworkAnalyzerService._internal();

  final List<VisitedDomain> _visitedDomains = [];
  final _domainController = StreamController<List<VisitedDomain>>.broadcast();
  bool _isAnalyzing = false;
  Timer? _analysisTimer;
  static const int _maxDomains = 1000; // Maksimum domain sayısı
  static const Duration _analysisInterval = Duration(seconds: 2);

  Stream<List<VisitedDomain>> get visitedDomainsStream => _domainController.stream;
  List<VisitedDomain> get visitedDomains => List.unmodifiable(_visitedDomains);

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

      _addNewDomain();
    });
  }

  void _addNewDomain() {
    try {
      // Maksimum domain sayısını kontrol et
      if (_visitedDomains.length >= _maxDomains) {
        _visitedDomains.removeAt(0); // En eski domaini kaldır
      }

      final newDomain = VisitedDomain(
        url: 'https://www.freemoney.com/free-bonus${_visitedDomains.length + 1}',
        timestamp: DateTime.now(),
      );
      
      _visitedDomains.add(newDomain);
      _domainController.add(_visitedDomains);
    } catch (e) {
      debugPrint('Domain eklenirken hata oluştu: $e');
    }
  }

  void clearDomains() {
    _visitedDomains.clear();
    _domainController.add(_visitedDomains);
  }

  void dispose() {
    stopAnalyzing();
    _domainController.close();
  }
} 