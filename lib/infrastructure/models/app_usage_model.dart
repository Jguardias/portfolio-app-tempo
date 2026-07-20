import 'dart:typed_data';

class AppUsageModel {
  final String packageName;
  final Duration totalTimeInForeground;
  final DateTime lastTimeUsed;
  final Uint8List? icon;
  final int launchCount;
  final DateTime firstUsedMs;

  AppUsageModel({

    required this.packageName,
    required this.lastTimeUsed,
    required this.totalTimeInForeground,
    this.icon, 
    required this.launchCount, 
    required this.firstUsedMs,
  });

  factory AppUsageModel.fromCalculatedData({
    required String packageName,
    required int totalTimeMs,
    required int lastUsedMs,
  required int launchCount, 
    required int firstUsedMs,
  }) {
    return AppUsageModel(
      packageName: packageName,
      totalTimeInForeground: Duration(milliseconds: totalTimeMs),
      lastTimeUsed: DateTime.fromMillisecondsSinceEpoch(lastUsedMs), 
      launchCount: launchCount,
       firstUsedMs: DateTime.fromMillisecondsSinceEpoch(firstUsedMs),
    );
  }
}
