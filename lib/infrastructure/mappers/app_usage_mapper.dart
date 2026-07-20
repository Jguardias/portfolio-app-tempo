import 'package:tempo/domain/entities/app_usage.dart';
import 'package:tempo/infrastructure/models/app_usage_model.dart';

class AppUsageMapper {
 
  static AppUsage toEntity(AppUsageModel model) {
    return AppUsage(
      packageName: model.packageName,
      lastTimeUsed: model.lastTimeUsed,
      totalTimeInForeground: model.totalTimeInForeground,
      firstUsed: model.firstUsedMs,
      launchCount: model.launchCount,
    );
  }
}