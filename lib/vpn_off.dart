import 'package:flutter/material.dart';
import 'services/vpn_service.dart';

/// This class represents the VPN Off page and allows interaction to enable the VPN.
class VpnOff extends StatefulWidget {
  const VpnOff({super.key});

  @override
  State<VpnOff> createState() => _VpnOffState();
}

class _VpnOffState extends State<VpnOff> {
  final VpnService _vpnService = VpnService();
  bool _isVpnActive = false;

  @override
  void initState() {
    super.initState();
    _isVpnActive = _vpnService.isVpnActive;
    _vpnService.vpnStatusStream.listen((active) {
      if (mounted) {
        setState(() {
          _isVpnActive = active;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = _isVpnActive 
        ? Colors.blue 
        : (isDark ? Colors.grey[900] : Colors.white);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: Row(
          children: [
            Icon(
              Icons.shield_outlined,
              color: _isVpnActive 
                  ? Colors.white 
                  : (isDark ? Colors.blue : Colors.blue),
            ),
            const SizedBox(width: 8),
            Text(
              'VPN',
              style: TextStyle(
                color: _isVpnActive 
                    ? Colors.white 
                    : (isDark ? Colors.white : Colors.blue),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: _isVpnActive
            ? [
                TextButton.icon(
                  onPressed: () {
                    _vpnService.toggleVpn();
                  },
                  icon: const Icon(Icons.power_settings_new, color: Colors.white),
                  label: const Text(
                    'Kapat',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ]
            : null,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isVpnActive) ...[
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'VPN Durumu: Aktif',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Güvendesiniz.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ] else
              Stack(
                alignment: Alignment.center,
                children: [
                  for (int i = 1; i <= 3; i++)
                    Container(
                      width: 80.0 * i,
                      height: 80.0 * i,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark 
                              ? Colors.blue.withOpacity(0.4)
                              : Colors.blue.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                    ),
                  GestureDetector(
                    onTap: () {
                      _vpnService.toggleVpn();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(_isVpnActive 
                            ? 'VPN kapatılıyor...' 
                            : 'VPN başlatılıyor...'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.power_settings_new,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
