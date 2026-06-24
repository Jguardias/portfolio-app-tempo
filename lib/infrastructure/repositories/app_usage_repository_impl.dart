import 'package:tempo/domain/entities/app_usage.dart';
import 'package:tempo/domain/repositories/app_usage_repository.dart';
import 'package:tempo/domain/datasources/app_usage_datasource.dart';

class AppUsageRepositoryImpl implements AppUsageRepositories {
  final AppUsageDatasources dataSource;
  AppUsageRepositoryImpl(this.dataSource);

  @override
  Future<List<AppUsage>> getDailyUsageStats() {
    return dataSource.getDailyUsageStats();
  }
}
