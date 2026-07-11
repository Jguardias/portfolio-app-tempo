import 'dart:typed_data';

class AppUsageModel {
  final String packageName;
  final String appName;
  final Duration totalTimeInForeground;
  final DateTime lastTimeUsed;
  final Uint8List? icon;

  AppUsageModel({
    required this.appName,
    required this.packageName,
    required this.lastTimeUsed,
    required this.totalTimeInForeground,
    this.icon
  });

factory AppUsageModel.fromCalculatedData({
    required String packageName,
    required int totalTimeMs,
    required int lastUsedMs,
  }) {
    return AppUsageModel(
      packageName: packageName,
      appName: "", 
      totalTimeInForeground: Duration(milliseconds: totalTimeMs),
      lastTimeUsed: DateTime.fromMillisecondsSinceEpoch(lastUsedMs),
    );
  }
}

