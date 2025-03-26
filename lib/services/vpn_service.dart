import 'dart:async';
import 'package:rorusheild2/utils/platform_channel.dart';

class VpnService {
  static final VpnService _instance = VpnService._internal();
  factory VpnService() => _instance;
  VpnService._internal();

  bool _isVpnActive = false;
  final _vpnController = StreamController<bool>.broadcast();

  Stream<bool> get vpnStatusStream => _vpnController.stream;
  bool get isVpnActive => _isVpnActive;

  void toggleVpn() {
    if (_isVpnActive) {
      _stopVpn();
    } else {
      _startVpn();
    }
  }

  Future<void> _startVpn() async {
    try {
      await PlatformChannel.startVpn(); // Send command to Android to start VPN
      _isVpnActive = true;
      _vpnController.add(true);
    } catch (e) {
      // Handle error if starting VPN fails
      print("Error starting VPN: $e");
    }
  }

  void _stopVpn() {
    try {
      PlatformChannel.stopVpn(); // Send command to Android to stop VPN
      _isVpnActive = false;
      _vpnController.add(false);
    } catch (e) {
      // Handle error if stopping VPN fails
      print("Error stopping VPN: $e");
    }
  }
}
