import 'package:tempo/domain/datasources/app_usage_datasource.dart';
import 'package:tempo/domain/entities/app_usage.dart';
import 'package:tempo/infrastructure/datasources/helpers/usage_event_tracker.dart';
import 'package:tempo/infrastructure/datasources/helpers/usage_stats_processor.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:tempo/infrastructure/mappers/app_usage_mapper.dart';

class AppUsageDatasourceImpl implements AppUsageDatasources {
  final UsageEventTracker _tracker = UsageEventTracker();

  bool _permissionGranted = false;
  DateTime? _permissionCheckedAt;

  /// Cachea el permiso 30 s para no consultarlo en cada ciclo.
  Future<bool> _hasPermission() async {
    final checkedAt = _permissionCheckedAt;
    if (checkedAt != null &&
        _permissionGranted &&
        DateTime.now().difference(checkedAt).inSeconds < 30) {
      return true;
    }
    _permissionGranted = (await UsageStats.checkUsagePermission()) ?? false;
    _permissionCheckedAt = DateTime.now();
    return _permissionGranted;
  }

  @override
  Future<List<AppUsage>> getDailyUsageStats() async {
    if (!await _hasPermission()) return [];

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day, 0, 0, 0);

    List<UsageInfo> usage = await UsageStats.queryUsageStats(startOfToday, now);
    List<EventUsageInfo> events = await UsageStats.queryEvents(startOfToday, now);

    final models =
        UsageStatsProcessor.process(usage, events, startOfToday, now: now);

    final entities = models.map((m) => AppUsageMapper.toEntity(m)).toList();
    entities.sort(
        (a, b) => b.totalTimeInForeground.compareTo(a.totalTimeInForeground));

    return entities;
  }

  @override
  Future<Duration> getDailyUsageForPackage(String packageName) async {
    if (!await _hasPermission()) return Duration.zero;
    await _tracker.refresh();
    return _tracker.usageFor(packageName);
  }

  @override
  Future<String?> getForegroundAppPackageName() async {
    if (!await _hasPermission()) return null;
    await _tracker.refresh();
    return _tracker.currentForeground;
  }
}