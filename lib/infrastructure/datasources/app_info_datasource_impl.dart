import 'package:tempo/domain/entities/app_info_device.dart';
import 'package:flutter_device_apps/flutter_device_apps.dart';
import 'package:tempo/domain/datasources/app_usage_datasource.dart';
import 'package:tempo/infrastructure/mappers/app_info_mapper.dart';
import 'package:tempo/infrastructure/models/app_metadata_model.dart';

class AppInfoDatasourceImpl implements AppInfoDatasource {
  @override
  Future<AppInfoDevice> getAppInfo(String packageName) async {
    final appInfo = await FlutterDeviceApps.getApp(
      packageName,
      includeIcon: true,
    );
    final AppMetaData model = AppMetaData.fromFlutterDevice(appInfo);
    final app = AppInfoMapper.toEntity(model);
    return app;
  }

@override
  Future<List<AppInfoDevice>> getInstalledApps() async {
  
    final apps = await FlutterDeviceApps.listApps(
      includeIcons: true,
      includeSystem: false,
      onlyLaunchable: true,
    );

    return apps.map((app) {
      final model = AppMetaData.fromFlutterDevice(app);
      return AppInfoMapper.toEntity(model);
    }).toList();
  }
}

