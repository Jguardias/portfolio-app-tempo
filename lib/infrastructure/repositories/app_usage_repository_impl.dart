import 'package:tempo/domain/entities/app_usage.dart';
import 'package:tempo/domain/repositories/app_usage_repository.dart';
import 'package:tempo/domain/datasources/app_usage_datasource.dart';

class AppUsageRepositoryImpl implements AppUsageRepositories {
  final AppUsageDatasources dataSource;
  final AppInfoDatasource infoAppDatasource;
  AppUsageRepositoryImpl(this.dataSource, this.infoAppDatasource);

  @override
  Future<List<AppUsage>> getDailyUsageStats() async {
    
    final apps = await dataSource.getDailyUsageStats();

    return await Future.wait(
      apps.map((app) async {
        final infoDevice = await infoAppDatasource.getAppInfo(app.packageName);
    
        return AppUsage(
        packageName: app.packageName,
        appName: infoDevice.appName ?? app.packageName,
        totalTimeInForeground: app.totalTimeInForeground,
        lastTimeUsed: app.lastTimeUsed,
        icon: infoDevice.icon,
        category: infoDevice.category,
        isSystemApp: infoDevice.isSystemApp,
        firstUsed: app.firstUsed,
        launchCount: app.launchCount,
      );
      }),
    );
  }
}
