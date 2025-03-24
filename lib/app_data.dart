import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/material.dart';

class AppData {
  final String appName;
  final double dataUsed;
  final IconData icon;

  AppData({required this.appName, required this.dataUsed, required this.icon});
}

final List<AppData> appUsageData = [
  AppData(appName: 'Instagram', dataUsed: 12.34, icon: FontAwesomeIcons.instagram),
  AppData(appName: 'YouTube', dataUsed: 14.26, icon: FontAwesomeIcons.youtube),
  AppData(appName: 'Spotify', dataUsed: 8.92, icon: FontAwesomeIcons.spotify),
  AppData(appName: 'Telegram', dataUsed: 5.64, icon: FontAwesomeIcons.telegram),
  AppData(appName: 'LinkedIn', dataUsed: 3.45, icon: FontAwesomeIcons.linkedin),
];



