import 'package:tempo/infrastructure/models/app_usage_model.dart';
import 'package:usage_stats/usage_stats.dart';

class UsageStatsProcessor {
  static const String _eventForeground = '1';
  static const String _eventBackground = '2';
  static const String _eventScreenOff = '16';

  static List<AppUsageModel> process(
    List<UsageInfo> rawUsageData,
    List<EventUsageInfo> eventLogs,
    DateTime startOfToday, {
    DateTime? now,
  }) {
    final Map<String, int> totalUsageMs = {};
    final Map<String, int> lastUsedTimestamp = {};
    final Map<String, int> launchCount = {};
    final Map<String, int> firstUsedTimestamp = {};
    final Map<String, int> activeSessions = {};

    final int startOfDayMs = startOfToday.millisecondsSinceEpoch;
    final int nowMs = (now ?? DateTime.now()).millisecondsSinceEpoch;

    void closeSession(String pkg, int endTs) {
      final int? sessionStart = activeSessions.remove(pkg);
      if (sessionStart == null) return;
      final int effectiveStart =
          (sessionStart < startOfDayMs) ? startOfDayMs : sessionStart;
      final int duration = endTs - effectiveStart;
      if (duration > 0) {
        totalUsageMs[pkg] = (totalUsageMs[pkg] ?? 0) + duration;
      }
    }

    for (var event in eventLogs) {
      final String type = event.eventType ?? '';
      final int timestamp = int.tryParse(event.timeStamp ?? '0') ?? 0;

      // Pantalla apagada: se cierran todas las sesiones abiertas
      if (type == _eventScreenOff) {
        for (final pkg in activeSessions.keys.toList()) {
          closeSession(pkg, timestamp);
        }
        continue;
      }

      final String? pkg = event.packageName;
      if (pkg == null) continue;
      if (type != _eventForeground && type != _eventBackground) continue;

      if (type == _eventForeground) {
        // Solo una app puede estar al frente: cerrar sesiones abiertas de otras
        for (final other in activeSessions.keys.toList()) {
          if (other != pkg) closeSession(other, timestamp);
        }
        launchCount[pkg] = (launchCount[pkg] ?? 0) + 1;

        if (firstUsedTimestamp[pkg] == null ||
            timestamp < firstUsedTimestamp[pkg]!) {
          firstUsedTimestamp[pkg] = timestamp;
        }
        activeSessions.putIfAbsent(pkg, () => timestamp);
      } else {
        closeSession(pkg, timestamp);
      }

      if (timestamp > (lastUsedTimestamp[pkg] ?? 0)) {
        lastUsedTimestamp[pkg] = timestamp;
      }
    }

    // Sesiones todavía abiertas: se cuentan hasta el momento actual
    for (final pkg in activeSessions.keys.toList()) {
      closeSession(pkg, nowMs);
    }

    for (var info in rawUsageData) {
      final String? pkg = info.packageName;
      if (pkg == null) continue;

      // Solo apps que se hayan abierto hoy
      if ((launchCount[pkg] ?? 0) == 0) continue;

      final int totalTime = int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
      if ((totalUsageMs[pkg] ?? 0) == 0 && totalTime > 0) {
        totalUsageMs[pkg] = totalTime;
      }

      final int lastUsed = int.tryParse(info.lastTimeUsed ?? '0') ?? 0;
      if (lastUsed > (lastUsedTimestamp[pkg] ?? 0)) {
        lastUsedTimestamp[pkg] = lastUsed;
      }
    }

    return totalUsageMs.entries
        .where((entry) => entry.value > 0)
        .map((entry) => AppUsageModel.fromCalculatedData(
              packageName: entry.key,
              totalTimeMs: entry.value,
              lastUsedMs: lastUsedTimestamp[entry.key] ?? 0,
              launchCount: launchCount[entry.key] ?? 0,
              firstUsedMs: firstUsedTimestamp[entry.key] ?? 0,
            ))
        .toList();
  }
}