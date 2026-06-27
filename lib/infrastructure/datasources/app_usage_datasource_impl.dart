import 'dart:typed_data';
import 'package:flutter_device_apps/flutter_device_apps.dart';
import 'package:tempo/domain/datasources/app_usage_datasource.dart';
import 'package:tempo/domain/entities/app_usage.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:tempo/infrastructure/models/app_usage_model.dart';
import 'package:tempo/infrastructure/mappers/app_usage_mapper.dart';

class AppUsageDatasourceImpl implements AppUsageDatasources {
  @override
  Future<List<AppUsage>> getDailyUsageStats() async {
    bool? granted = await UsageStats.checkUsagePermission();

    if (granted != true) {
      await UsageStats.grantUsagePermission();
      return [];
    }
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 1));
    List<UsageInfo> usage = await UsageStats.queryUsageStats(
      startDate,
      endDate,
    );

    final List<AppUsage> appsUsage = usage
        .map((appUsageJson) => AppUsageModel.fromJson(appUsageJson))
        .map((appUsageModel) => AppUsageMapper.toEntity(appUsageModel))
        .toList();

    return appsUsage;
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
}
