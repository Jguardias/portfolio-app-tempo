import 'package:tempo/domain/entities/app_info_device.dart';
import 'package:tempo/domain/entities/app_usage.dart';

abstract class AppUsageDatasources {
  Future<List<AppUsage>> getDailyUsageStats();
  Future<String?> getForegroundAppPackageName();
}

abstract class AppInfoDatasource {
  Future<AppInfoDevice> getAppInfo(String packageName);
  Future<List<AppInfoDevice>> getInstalledApps();
}
