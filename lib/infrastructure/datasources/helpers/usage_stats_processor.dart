import 'package:tempo/infrastructure/models/app_usage_model.dart';
import 'package:usage_stats/usage_stats.dart';

class UsageStatsProcessor {
  static List<AppUsageModel> process(List<UsageInfo> rawUsage, DateTime startOfToday) {
    final Map<String, int> consolidatedTime = {};
    final Map<String, int> lastUsedMap = {};

    for (var info in rawUsage) {
      if (info.packageName == null) continue;
      
      final int totalTime = int.tryParse(info.totalTimeInForeground ?? '0') ?? 0;
      final int lastUsed = int.tryParse(info.lastTimeUsed ?? '0') ?? 0;

      if (lastUsed >= startOfToday.millisecondsSinceEpoch) {
        consolidatedTime[info.packageName!] = (consolidatedTime[info.packageName!] ?? 0) + totalTime;
        lastUsedMap[info.packageName!] = (lastUsed > (lastUsedMap[info.packageName!] ?? 0)) 
            ? lastUsed 
            : (lastUsedMap[info.packageName!] ?? 0);
      }
    }

    return consolidatedTime.entries
        .where((entry) => entry.value > 0)
        .map((entry) => AppUsageModel.fromCalculatedData(
              packageName: entry.key,
              totalTimeMs: entry.value,
              lastUsedMs: lastUsedMap[entry.key] ?? 0,
            ))
        .toList();
  }
}