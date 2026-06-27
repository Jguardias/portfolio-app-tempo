import 'package:tempo/domain/entities/app_usage.dart';
import 'package:tempo/domain/repositories/app_usage_repository.dart';
import 'package:tempo/domain/datasources/app_usage_datasource.dart';

class AppUsageRepositoryImpl implements AppUsageRepositories {
  final AppUsageDatasources dataSource;
  final AppIconDatasource iconDatasource;
  AppUsageRepositoryImpl(this.dataSource, this.iconDatasource);

  @override
  Future<List<AppUsage>> getDailyUsageStats() async {
    final apps = await dataSource.getDailyUsageStats();

    return await Future.wait(
      apps.map((app) async {
        final icon = await iconDatasource.getIcon(app.packageName);
        return AppUsage(
        packageName: app.packageName,
        appName: app.appName,
        totalTimeInForeground: app.totalTimeInForeground,
        lastTimeUsed: app.lastTimeUsed,
        icon: icon,
      );
      }),
    );
  }
}
