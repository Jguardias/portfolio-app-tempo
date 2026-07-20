import 'dart:typed_data';

class AppInfoDevice {
  final String? appName;
  final Uint8List? icon;
  final bool? isSystemApp;
  final String category;
  AppInfoDevice({
    required this.appName,
    required this.icon,
    required this.isSystemApp, 
    required this.category,
  });
}