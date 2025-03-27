import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'services/network_analyzer_service.dart';
import 'models/visited_domain.dart';
import 'services/database_service.dart';

class UnsafeLogs extends StatefulWidget {
  const UnsafeLogs({super.key});

  @override
  State<UnsafeLogs> createState() => _UnsafeLogsState();
}

class _UnsafeLogsState extends State<UnsafeLogs> with AutomaticKeepAliveClientMixin {
  final NetworkAnalyzerService _networkAnalyzer = NetworkAnalyzerService.instance;
  final DatabaseService _dbService = DatabaseService.instance;
  List<VisitedDomain> _unsafeDomains = [];
  StreamSubscription? _subscription;
  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;  // Ekran değişse bile durumu koru

  @override
  void initState() {
    super.initState();
    _loadDomains();
    _subscription = NetworkAnalyzerService.instance.dangerousDomainsStream.listen((domains) {
      _loadDomains();
    });
  }

  Future<void> _loadDomains() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Tehlikeli domainleri yükle, yeni eklenenler en üstte olacak
      final domains = await _dbService.getDangerousDomains();
      if (mounted) {
        setState(() {
          _unsafeDomains = domains;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Tehlikeli domainler yüklenirken hata: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // AutomaticKeepAliveClientMixin için gerekli
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Tehlikeli Bağlantılar',
          style: TextStyle(
            color: Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.red),
            onPressed: _loadDomains,
          ),
        ],
      ),
      backgroundColor: Colors.white,
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _unsafeDomains.isEmpty
              ? const Center(
                  child: Text(
                    'Henüz tehlikeli bağlantı bulunmuyor',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _unsafeDomains.length,
                  itemBuilder: (context, index) {
                    final domain = _unsafeDomains[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: const CircleAvatar(
                            backgroundColor: Colors.red,
                            radius: 16,
                            child: Icon(Icons.warning, color: Colors.white, size: 18),
                          ),
                          title: Text(
                            domain.url,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            _formatDate(domain.timestamp),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
