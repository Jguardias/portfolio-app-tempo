import 'dart:typed_data';
import 'package:flutter_device_apps/flutter_device_apps.dart';

class AppMetaData {
  final String? appName;
  final Uint8List? icon;
  final bool? isSystemApp;
  final int? category;
  AppMetaData({
    required this.appName,
    required this.icon,
    required this.isSystemApp,
    required this.category,
  });

  factory AppMetaData.fromFlutterDevice(AppInfo? infoAppFlutterDivice) =>
      AppMetaData(
        appName: infoAppFlutterDivice?.appName,
        icon: infoAppFlutterDivice?.iconBytes,
        isSystemApp: infoAppFlutterDivice?.isSystem,
        category: infoAppFlutterDivice?.category,
      );
}
