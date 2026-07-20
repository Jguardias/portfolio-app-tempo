import 'dart:typed_data';

class AppUsage {
  final String packageName;
  final String?appName;
  final Duration totalTimeInForeground;
  final DateTime lastTimeUsed;
  final DateTime? firstUsed;
  final Uint8List? icon;
  final int launchCount;
  final String category;
  final bool? isSystemApp;


  AppUsage({
    this.appName,
    required this.packageName,
    required this.lastTimeUsed,
    required this.totalTimeInForeground,
    this.icon, 
    this.firstUsed,
    this.launchCount = 0,
    this.category = 'Otro', 
    this.isSystemApp = false,
  });
}
