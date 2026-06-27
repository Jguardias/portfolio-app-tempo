import 'dart:typed_data';

class AppUsage {
  final String packageName;
  final String appName;
  final Duration totalTimeInForeground;
  final DateTime lastTimeUsed;
  final Uint8List? icon;

  AppUsage({
    required this.appName,
    required this.packageName,
    required this.lastTimeUsed,
    required this.totalTimeInForeground, 
    required this.icon,
  });
}
