import 'package:tempo/domain/entities/app_usage.dart';

abstract class AppUsageRepositories {
  Future<List<AppUsage>> getDailyUsageStats();
  Future<List<AppUsage>> getAllApps();
  Future<String?> getForegroundAppPackageName();
}

