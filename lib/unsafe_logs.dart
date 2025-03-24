import 'package:flutter/material.dart';
import 'services/network_analyzer_service.dart';

class UnsafeLogs extends StatefulWidget {
  const UnsafeLogs({super.key});

  @override
  State<UnsafeLogs> createState() => _UnsafeLogsState();
}

class _UnsafeLogsState extends State<UnsafeLogs> {
  final NetworkAnalyzerService _networkAnalyzer = NetworkAnalyzerService();
  List<VisitedDomain> _unsafeDomains = [];

  @override
  void initState() {
    super.initState();
    _networkAnalyzer.visitedDomainsStream.listen((domains) {
      if (mounted) {
        setState(() {
          _unsafeDomains = domains;
        });
      }
    });
  }

  String _formatDate(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Güvenli Olmayan Bağlantılar',
          style: TextStyle(
            color: Colors.blue,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      body: _unsafeDomains.isEmpty
          ? const Center(
              child: Text(
                'Henüz güvenli olmayan bağlantı bulunmuyor',
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
                      color: const Color(0xFF2196F3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: const CircleAvatar(
                        backgroundColor: Colors.blue,
                        radius: 16,
                        child: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
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
