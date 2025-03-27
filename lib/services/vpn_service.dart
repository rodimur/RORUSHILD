import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VpnService {
  static final VpnService _instance = VpnService._internal();
  factory VpnService() => _instance;
  
  // Method channel for native communication
  static const MethodChannel _channel = MethodChannel('com.example.rorusheild2/vpn_channel');
  
  // Stream controller for broadcasting VPN status
  final _vpnController = StreamController<bool>.broadcast();
  
  // VPN status
  bool _isVpnActive = false;
  
  // Getters
  Stream<bool> get vpnStatusStream => _vpnController.stream;
  bool get isVpnActive => _isVpnActive;

  VpnService._internal() {
    _initVpn();
  }

  // Initialize VPN
  void _initVpn() {
    // VPN durum değişikliklerini dinle
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'vpnStatus':
          final String status = call.arguments as String;
          debugPrint("VPN durumu değişti: $status");
          
          final bool isConnected = status == 'active';
          if (_isVpnActive != isConnected) {
            _isVpnActive = isConnected;
            _vpnController.add(isConnected);
          }
          break;
      }
      return null;
    });
    
    // Mevcut VPN durumunu kontrol et
    _checkVpnStatus();
  }
  
  // Check current VPN status
  Future<void> _checkVpnStatus() async {
    try {
      final bool isActive = await _channel.invokeMethod('checkVpnStatus');
      if (_isVpnActive != isActive) {
        _isVpnActive = isActive;
        _vpnController.add(isActive);
      }
    } catch (e) {
      debugPrint("VPN durum kontrolü hatası: $e");
    }
  }
  
  // Toggle VPN connection
  void toggleVpn() {
    if (_isVpnActive) {
      _stopVpn();
    } else {
      _startVpn();
    }
  }
  
  // Start VPN connection
  Future<void> _startVpn() async {
    try {
      final String result = await _channel.invokeMethod('startVpn');
      debugPrint("VPN başlatma sonucu: $result");
    } catch (e) {
      debugPrint("VPN başlatma hatası: $e");
    }
  }
  
  // Stop VPN connection
  Future<void> _stopVpn() async {
    try {
      final String result = await _channel.invokeMethod('stopVpn');
      debugPrint("VPN durdurma sonucu: $result");
    } catch (e) {
      debugPrint("VPN durdurma hatası: $e");
    }
  }
  
  // Cleanup resources
  void dispose() {
    _vpnController.close();
  }
}
