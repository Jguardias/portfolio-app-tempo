import 'dart:typed_data';
import 'package:flutter_device_apps/flutter_device_apps.dart';

class AppMetaData {
  final String packageName;
  final String? appName;
  final Uint8List? icon;
  final bool? isSystemApp;
  final int? category;
  AppMetaData({
    required this.appName,
    required this.icon,
    required this.isSystemApp,
    required this.category, required this.packageName,
  });

  factory AppMetaData.fromFlutterDevice(AppInfo? infoAppFlutterDivice) =>
      AppMetaData(
        packageName: infoAppFlutterDivice?.packageName ?? '',
        appName: infoAppFlutterDivice?.appName,
        icon: infoAppFlutterDivice?.iconBytes,
        isSystemApp: infoAppFlutterDivice?.isSystem,
        category: infoAppFlutterDivice?.category,
      );
}
