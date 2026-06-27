import 'package:tempo/domain/entities/app_usage.dart';
import 'package:tempo/infrastructure/models/app_usage_model.dart';

class AppUsageMapper {
  static AppUsage toEntity(AppUsageModel dto) {
    return AppUsage(
      packageName: dto.packageName,
      appName: dto.appName,
      lastTimeUsed: dto.lastTimeUsed,
      totalTimeInForeground:  dto.totalTimeInForeground,
      icon: dto.icon
    );
  }
}