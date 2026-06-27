import 'package:tempo/domain/entities/app_usage.dart';

abstract class AppUsageRepositories {
  Future<List<AppUsage>> getDailyUsageStats();
}

