import 'dart:typed_data';
import 'package:flutter_device_apps/flutter_device_apps.dart';
import 'package:tempo/domain/datasources/app_usage_datasource.dart';
import 'package:tempo/domain/entities/app_usage.dart';
import 'package:tempo/infrastructure/datasources/helpers/usage_stats_processor.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:tempo/infrastructure/mappers/app_usage_mapper.dart';

class AppUsageDatasourceImpl implements AppUsageDatasources {
  @override
  Future<List<AppUsage>> getDailyUsageStats() async {
    bool? granted = await UsageStats.checkUsagePermission();
    if (granted != true) {
      await UsageStats.grantUsagePermission();
      return [];
    }

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day, 0, 0, 0);

    List<UsageInfo> usage = await UsageStats.queryUsageStats(startOfToday, now);

    final models = UsageStatsProcessor.process(usage, startOfToday);

    final entities = models.map((m) => AppUsageMapper.toEntity(m)).toList();
    entities.sort((a, b) => b.totalTimeInForeground.compareTo(a.totalTimeInForeground));

    return entities;
  }
}

class AppIconDatasourceImpl implements AppIconDatasource {
  @override
  Future<Uint8List?> getIcon(String packageName) async {
    final appInfo = await FlutterDeviceApps.getApp(
      packageName,
      includeIcon: true,
    );
    return appInfo?.iconBytes;
  }

  @override
  Future<String?> getAppName(String packageName) async {
    final appInfo = await FlutterDeviceApps.getApp(
      packageName,
      includeIcon: true,
    );
    return appInfo?.packageName;
  }
}
