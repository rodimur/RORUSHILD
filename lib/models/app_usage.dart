import 'dart:ui';

class AppUsage {
  final String appName;
  final String iconPath;
  final double dataUsage;
  final Color backgroundColor;

  AppUsage({
    required this.appName,
    required this.iconPath,
    required this.dataUsage,
    required this.backgroundColor,
  });
}

class DataUsageCategory {
  final String name;
  final String icon;
  final double usage;

  DataUsageCategory({
    required this.name,
    required this.icon,
    required this.usage,
  });
} 