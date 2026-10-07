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
    List<EventUsageInfo> events = await UsageStats.queryEvents(startOfToday, now);

    final models = UsageStatsProcessor.process(usage,events, startOfToday);

    final entities = models.map((m) => AppUsageMapper.toEntity(m)).toList();
    entities.sort((a, b) => b.totalTimeInForeground.compareTo(a.totalTimeInForeground));

    return entities;
  }

@override
  Future<String?> getForegroundAppPackageName() async {
    bool? granted = await UsageStats.checkUsagePermission();
    if (granted != true) return null;

    final now = DateTime.now();
    // Consultamos una ventana de tiempo corta (10 segundos atrás)
    final startDate = now.subtract(const Duration(seconds: 10));

    List<EventUsageInfo> events = await UsageStats.queryEvents(startDate, now);

    if (events.isEmpty) return null;

    // Recorremos desde el evento más reciente hacia el más antiguo.
    // '1' corresponde al evento MOVE_TO_FOREGROUND / ACTIVITY_RESUMED en Android.
    for (var i = events.length - 1; i >= 0; i--) {
      final event = events[i];
      if (event.eventType == '1' && event.packageName != null) {
        return event.packageName;
      }
    }

    return null;
  }
}

