import 'dart:typed_data';
import 'package:tempo/domain/entities/app_usage.dart';


abstract class AppUsageDatasources {
   Future<List<AppUsage>> getDailyUsageStats();
}

abstract class AppIconDatasource {
  Future<Uint8List?> getIcon(String packageName);
}