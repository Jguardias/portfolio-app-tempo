import 'package:tempo/infrastructure/services/pause_event_store.dart';

class AppSummary {
  final String packageName;
  final int pauses;
  final int exits;
  final Map<String, int> intents;

  const AppSummary({
    required this.packageName,
    required this.pauses,
    required this.exits,
    required this.intents,
  });

  String? get topIntent {
    if (intents.isEmpty) return null;
    final sorted = intents.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }
}

class PauseSummary {
  final int totalPauses;
  final int exits;
  final int answered;
  final Map<String, int> intents;
  final List<AppSummary> apps;

  const PauseSummary({
    required this.totalPauses,
    required this.exits,
    required this.answered,
    required this.intents,
    required this.apps,
  });

  bool get isEmpty => totalPauses == 0;
}

class SummaryCalculator {
  static const Map<String, String> intentLabels = {
    'search': 'Buscar algo específico',
    'message': 'Revisar un mensaje',
    'entertain': 'Entretenerme un rato',
    'habit': 'Costumbre',
    'other': 'Otro motivo',
  };

  /// Resume los eventos de los últimos [days] días (incluido hoy).
  /// [mode] puede ser 'open', 'time' o null (todos).
  static PauseSummary compute(
    List<PauseEvent> events,
    DateTime now, {
    int days = 7,
    String? mode,
  }) {
    final start =
        DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));
    final startMs = start.millisecondsSinceEpoch;

    final filtered = events
        .where((e) => e.time >= startMs && (mode == null || e.mode == mode))
        .toList();

    final byApp = <String, List<PauseEvent>>{};
    for (final e in filtered) {
      byApp.putIfAbsent(e.packageName, () => []).add(e);
    }

    final apps = byApp.entries
        .map((entry) => AppSummary(
              packageName: entry.key,
              pauses: entry.value.length,
              exits: entry.value.where(_isExit).length,
              intents: _intents(entry.value),
            ))
        .toList()
      ..sort((a, b) => b.pauses.compareTo(a.pauses));

    return PauseSummary(
      totalPauses: filtered.length,
      exits: filtered.where(_isExit).length,
      answered: filtered.where((e) => e.intent != null).length,
      intents: _intents(filtered),
      apps: apps,
    );
  }

  static bool _isExit(PauseEvent e) => e.action == 'exit' || e.action == 'left';

  static Map<String, int> _intents(Iterable<PauseEvent> list) {
    final map = <String, int>{};
    for (final e in list) {
      final i = e.intent;
      if (i != null) map[i] = (map[i] ?? 0) + 1;
    }
    return map;
  }
}