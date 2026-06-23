class AppUsage {
  final String packageName;
  final String appName;
  final Duration totalTimeInForeground;
  final DateTime lastTimeUsed;

  AppUsage({
    required this.appName,
    required this.packageName,
    required this.lastTimeUsed,
    required this.totalTimeInForeground,
  });
}
