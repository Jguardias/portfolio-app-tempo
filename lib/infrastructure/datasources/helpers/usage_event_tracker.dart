import 'package:usage_stats/usage_stats.dart';

/// Lee los eventos de uso de forma INCREMENTAL (solo los nuevos desde la última
/// lectura) y mantiene en memoria:
///  - la app en primer plano actual
///  - el tiempo acumulado hoy por app (incluyendo la sesión en curso)
class UsageEventTracker {
  static const String _resumed = '1';
  static const String _paused = '2';
  static const String _screenOff = '16';
  static const Duration _minRefreshGap = Duration(milliseconds: 1000);

  int _dayKey = -1;
  int _lastEventTs = 0;
  DateTime? _lastRefresh;
  bool _refreshing = false;

  String? _currentForeground;
  final Map<String, int> _totalMs = {};
  final Map<String, int> _openSince = {};

  String? get currentForeground => _currentForeground;

  /// Tiempo de hoy de la app, sumando la sesión abierta hasta este momento.
  Duration usageFor(String packageName) {
    int total = _totalMs[packageName] ?? 0;
    final open = _openSince[packageName];
    if (open != null) {
      final diff = DateTime.now().millisecondsSinceEpoch - open;
      if (diff > 0) total += diff;
    }
    return Duration(milliseconds: total);
  }

  Future<void> refresh() async {
    final now = DateTime.now();
    if (_refreshing) return;
    if (_lastRefresh != null && now.difference(_lastRefresh!) < _minRefreshGap) {
      return;
    }

    _refreshing = true;
    try {
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfDayMs = startOfDay.millisecondsSinceEpoch;

      // Cambio de día (o primera ejecución): reiniciar acumulados
      if (startOfDayMs != _dayKey) {
        _dayKey = startOfDayMs;
        _lastEventTs = startOfDayMs;
        _totalMs.clear();
        _openSince.clear();
        // Si había una app abierta pasada la medianoche, su sesión sigue
        if (_currentForeground != null) {
          _openSince[_currentForeground!] = startOfDayMs;
        }
      }

      final from = DateTime.fromMillisecondsSinceEpoch(_lastEventTs);
      final events = await UsageStats.queryEvents(from, now);

      final parsed = <_Ev>[];
      for (final e in events) {
        final ts = int.tryParse(e.timeStamp ?? '');
        if (ts == null || ts <= _lastEventTs) continue;
        parsed.add(_Ev(ts, e.eventType ?? '', e.packageName));
      }
      parsed.sort((a, b) => a.ts.compareTo(b.ts));

      int maxTs = _lastEventTs;
      for (final ev in parsed) {
        if (ev.ts > maxTs) maxTs = ev.ts;

        if (ev.type == _screenOff) {
          // Pantalla apagada: cerrar todas las sesiones abiertas
          _openSince.forEach((pkg, start) {
            final d = ev.ts - start;
            if (d > 0) _totalMs[pkg] = (_totalMs[pkg] ?? 0) + d;
          });
          _openSince.clear();
          _currentForeground = null;
          continue;
        }

        final pkg = ev.pkg;
        if (pkg == null) continue;

        if (ev.type == _resumed) {
          // Solo una app puede estar al frente: si había otra sesión abierta,
          // se cierra en este instante (aunque nunca llegara su evento de pausa).
          for (final other in _openSince.keys.toList()) {
            if (other == pkg) continue;
            final start = _openSince.remove(other);
            if (start != null) {
              final d = ev.ts - start;
              if (d > 0) _totalMs[other] = (_totalMs[other] ?? 0) + d;
            }
          }
          _currentForeground = pkg;
          _openSince.putIfAbsent(pkg, () => ev.ts);
        } else if (ev.type == _paused) {
          final start = _openSince.remove(pkg);
          if (start != null) {
            final d = ev.ts - start;
            if (d > 0) _totalMs[pkg] = (_totalMs[pkg] ?? 0) + d;
          }
        }
      }

      _lastEventTs = maxTs;
      _lastRefresh = now;
    } finally {
      _refreshing = false;
    }
  }
}

class _Ev {
  final int ts;
  final String type;
  final String? pkg;
  _Ev(this.ts, this.type, this.pkg);
}