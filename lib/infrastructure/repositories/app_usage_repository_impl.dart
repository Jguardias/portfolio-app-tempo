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

@override
  Future<List<AppUsage>> getAllApps() async {
    final installedApps = await infoAppDatasource.getInstalledApps();
    final dailyStats = await dataSource.getDailyUsageStats();

    final statsMap = {for (var app in dailyStats) app.packageName: app};

    final allAppsList = installedApps.map((infoDevice) {
      final usage = statsMap[infoDevice.packageName];

      return AppUsage(
        packageName: infoDevice.packageName,
        appName: infoDevice.appName ?? infoDevice.packageName,
        totalTimeInForeground: usage?.totalTimeInForeground ?? Duration.zero,
        lastTimeUsed: usage?.lastTimeUsed ?? DateTime.fromMillisecondsSinceEpoch(0),
        icon: infoDevice.icon,
        category: infoDevice.category,
        isSystemApp: infoDevice.isSystemApp,
        firstUsed: usage?.firstUsed,
        launchCount: usage?.launchCount ?? 0,
      );
    }).toList();

    allAppsList.sort((a, b) =>
      (a.appName ?? '').toLowerCase().compareTo((b.appName ?? '').toLowerCase())
    );

    return allAppsList;
  }

@override
  Future<String?> getForegroundAppPackageName() {
    return dataSource.getForegroundAppPackageName();
  }
}
