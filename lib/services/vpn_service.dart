import 'dart:async';

class VpnService {
  static final VpnService _instance = VpnService._internal();
  factory VpnService() => _instance;
  VpnService._internal();

  bool _isVpnActive = false;
  final _vpnController = StreamController<bool>.broadcast();

  Stream<bool> get vpnStatusStream => _vpnController.stream;
  bool get isVpnActive => _isVpnActive;

  void toggleVpn() {
    _isVpnActive = !_isVpnActive;
    _vpnController.add(_isVpnActive);
  }
} 