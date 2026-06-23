class AppUsageModel {
  final String packageName;
  final String appName;
  final Duration totalTimeInForeground;
  final DateTime lastTimeUsed;

  AppUsageModel({
    required this.appName,
    required this.packageName,
    required this.lastTimeUsed,
    required this.totalTimeInForeground,
  });

  factory AppUsageModel.fromJson(Map<String, dynamic> json) {
    return AppUsageModel(
      packageName: json['packageName'],
      appName: json['appName'],
      totalTimeInForeground: Duration(milliseconds: json['totalTimeInForeground'] ?? 0),
      lastTimeUsed: DateTime.fromMillisecondsSinceEpoch(json['lastTimeUsed'] ?? 0),
    );
  }
}
