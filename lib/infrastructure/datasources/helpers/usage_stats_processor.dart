import 'package:tempo/infrastructure/models/app_usage_model.dart';
import 'package:usage_stats/usage_stats.dart';

class UsageStatsProcessor {
  static const String _eventForeground = '1';
  static const String _eventBackground = '2';

  static List<AppUsageModel> process(
    List<UsageInfo> rawUsageData,
    List<EventUsageInfo> eventLogs,
    DateTime startOfToday,
  ) {
    final Map<String, int> totalUsageMs = {};
    final Map<String, int> lastUsedTimestamp = {};
    final Map<String, int> launchCount = {};
    final Map<String, int> firstUsedTimestamp = {};
    final Map<String, int> activeSessions = {};
    
    final int startOfDayMs = startOfToday.millisecondsSinceEpoch;
   
    for (var event in eventLogs) {
      final String? pkg = event.packageName;
      if (pkg == null) continue;

      final int timestamp = int.tryParse(event.timeStamp ?? '0') ?? 0;
      final String type = event.eventType ?? '';
      if (type != '1' && type != '2') continue;
     
      if (type == _eventForeground) {
        launchCount[pkg] = (launchCount[pkg] ?? 0) + 1;
        
        if (firstUsedTimestamp[pkg] == null || timestamp < firstUsedTimestamp[pkg]!) {
          firstUsedTimestamp[pkg] = timestamp;
        }
        activeSessions[pkg] = timestamp;
      } else if (type == _eventBackground && activeSessions.containsKey(pkg)) {
        final int sessionStart = activeSessions[pkg]!;
        
        // Midnight boundary clamping
        final int effectiveStart = (sessionStart < startOfDayMs) ? startOfDayMs : sessionStart;
        final int duration = timestamp - effectiveStart;

        if (duration > 0) {
          totalUsageMs[pkg] = (totalUsageMs[pkg] ?? 0) + duration;
        }
        activeSessions.remove(pkg);
      }

      if (timestamp > (lastUsedTimestamp[pkg] ?? 0)) {
        lastUsedTimestamp[pkg] = timestamp;
      }
    }

for (var info in rawUsageData) {
      final String? pkg = info.packageName;
      if (pkg == null) continue;

      // Filter: Only include apps that have been actively launched
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