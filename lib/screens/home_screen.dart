import 'package:flutter/material.dart';
import 'dart:async';
import '../services/network_usage_service.dart';
import '../circular_data_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  Timer? _timer;
  bool _isDisposed = false;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    if (_isDisposed) return;
    
    setState(() => _isLoading = true);
    
    try {
      _hasPermission = await NetworkUsageService.checkAndRequestPermissions();
      if (_hasPermission) {
        await _loadRealTimeData();
        
        _timer?.cancel();
        _timer = Timer.periodic(const Duration(minutes: 3), (timer) async {
          if (!_isDisposed) {
            await _loadRealTimeData();
          }
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kullanım erişimi izni gerekli. Lütfen ayarlardan manuel olarak izin verin.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('İzin kontrolü hatası: $e');
      _hasPermission = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İzin kontrolü sırasında hata oluştu'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
    
    if (!_isDisposed && mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRealTimeData() async {
    if (_isDisposed) return;
    
    try {
      await NetworkUsageService.getRealTimeNetworkStats();
    } catch (e) {
      debugPrint('Veri yüklenemedi: $e');
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veri yüklenirken hata oluştu')),
        );
      }
    }
  }

  Future<void> _requestPermission() async {
    if (_isDisposed) return;
    
    setState(() => _isLoading = true);
    
    try {
      _hasPermission = await NetworkUsageService.checkAndRequestPermissions();
      if (_hasPermission) {
        await _loadRealTimeData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('İzin başarıyla verildi'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('İzin verilmedi. Lütfen ayarlardan manuel olarak izin verin.'),
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('İzin isteme hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İzin isteme sırasında hata oluştu'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
    
    if (!_isDisposed && mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _timer?.cancel();
    NetworkUsageService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : !_hasPermission
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.security,
                          size: 64,
                          color: Colors.blue,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Kullanım Erişimi Gerekli',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ağ kullanım istatistiklerini görüntülemek için\nkullanım erişimi izni vermeniz gerekiyor.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _requestPermission,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                          child: const Text('İzin Ver'),
                        ),
                      ],
                    ),
                  )
                : const CircularDataChart(),
      ),
    );
  }
} 