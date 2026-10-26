import 'package:tempo/domain/entities/app_info_device.dart';
import 'package:tempo/domain/entities/app_usage.dart';

abstract class AppUsageDatasources {
  Future<List<AppUsage>> getDailyUsageStats();

  /// Uso de hoy de UNA app, incluyendo la sesión que está en curso.
  Future<Duration> getDailyUsageForPackage(String packageName);

  Future<String?> getForegroundAppPackageName();
}

abstract class AppInfoDatasource {
  Future<AppInfoDevice> getAppInfo(String packageName);

  /// Solo el nombre (sin icono), mucho más liviano que getAppInfo.
  Future<String?> getAppName(String packageName);

  /// Categoría traducida ('Juegos', 'Redes Sociales', 'Video', ... o 'Otro').
  Future<String?> getAppCategory(String packageName);

  Future<List<AppInfoDevice>> getInstalledApps();
}