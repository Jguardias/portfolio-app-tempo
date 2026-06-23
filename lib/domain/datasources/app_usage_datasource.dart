import 'package:tempo/domain/entities/app_usage.dart';


abstract class AppUsageDatasources {
   Future<List<AppUsage>> getDailyUsageStats();
}