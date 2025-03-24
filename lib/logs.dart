import 'package:flutter/material.dart';
import 'services/network_analyzer_service.dart';
import 'package:intl/intl.dart';

class Logs extends StatefulWidget {
  const Logs({super.key});

  @override
  State<Logs> createState() => _LogsState();
}

class _LogsState extends State<Logs> {
  final NetworkAnalyzerService _networkAnalyzer = NetworkAnalyzerService();
  List<VisitedDomain> _visitedDomains = [];

  @override
  void initState() {
    super.initState();
    _networkAnalyzer.visitedDomainsStream.listen((domains) {
      setState(() {
        _visitedDomains = domains;
      });
    });
  }

  String _formatDate(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} ${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Ziyaret Edilen Bağlantılar',
          style: TextStyle(
            color: Colors.blue,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: _visitedDomains.isEmpty
          ? const Center(
              child: Text(
                'Henüz ziyaret edilen bağlantı bulunmuyor',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _visitedDomains.length,
              itemBuilder: (context, index) {
                final domain = _visitedDomains[index];
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
                        child: Icon(Icons.language, color: Colors.white, size: 18),
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
