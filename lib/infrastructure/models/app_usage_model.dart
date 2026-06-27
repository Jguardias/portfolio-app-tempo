import 'dart:typed_data';
import 'package:usage_stats/usage_stats.dart';

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

  factory AppUsageModel.fromJson(UsageInfo info) {
    final packageName = info.packageName ?? "Desconocida";
    final appName = packageName.split('.').last.toUpperCase();
    return AppUsageModel(
      packageName: packageName,
      appName:  appName,
      totalTimeInForeground: Duration(milliseconds: int.tryParse(info.totalTimeInForeground ?? '0') ?? 0),
      lastTimeUsed: DateTime.fromMillisecondsSinceEpoch(int.tryParse(info.lastTimeUsed ?? '0') ?? 0),
    );
  }
}
