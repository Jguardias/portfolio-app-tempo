import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Un evento = una pausa mostrada y cómo terminó.
/// action: continue | exit | left | timeout
/// intent: search | message | entertain | habit | other (o null si se omitió)
/// mode: open | time
class PauseEvent {
  final int time;
  final String packageName;
  final String mode;
  final String? intent;
  final String action;

  const PauseEvent({
    required this.time,
    required this.packageName,
    required this.mode,
    required this.intent,
    required this.action,
  });

  Map<String, dynamic> toJson() => {
        't': time,
        'p': packageName,
        'm': mode,
        'i': intent,
        'a': action,
      };

  factory PauseEvent.fromJson(Map<String, dynamic> j) => PauseEvent(
        time: (j['t'] as num).toInt(),
        packageName: j['p'] as String,
        mode: j['m'] as String? ?? 'time',
        intent: j['i'] as String?,
        action: j['a'] as String? ?? 'continue',
      );
}

/// Un solo escritor del registro: el servicio en segundo plano.
/// La ventana nativa solo escribe el "slot" (resultado de la pausa en curso).
class PauseEventStore {
  static const String _eventsKey = 'tempo_events';
  static const String _slotKey = 'tempo_pause_slot';
  static const String _askedPrefix = 'tempo_intent_asked_';
  static const String _intentModeKey = 'tempo_intent_mode';
  static const int maxEvents = 1000;

  static Future<SharedPreferences> _prefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs;
  }

  static List<PauseEvent> _decode(SharedPreferences prefs) {
    final raw = prefs.getString(_eventsKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => PauseEvent.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<PauseEvent>> readAll() async {
    return _decode(await _prefs());
  }

  static Future<void> append(PauseEvent event) async {
    final prefs = await _prefs();
    final events = _decode(prefs)..add(event);
    final trimmed = events.length > maxEvents
        ? events.sublist(events.length - maxEvents)
        : events;
    await prefs.setString(
      _eventsKey,
      jsonEncode(trimmed.map((e) => e.toJson()).toList()),
    );
  }

  /// Resultado de la pausa en curso, escrito por la ventana nativa.
  static Future<Map<String, dynamic>?> readSlot() async {
    final prefs = await _prefs();
    final raw = prefs.getString(_slotKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  static String _today() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  /// Según el ajuste del usuario: always | daily | never.
  static Future<bool> shouldAskIntent(String packageName) async {
    final prefs = await _prefs();
    final mode = prefs.getString(_intentModeKey) ?? 'always';
    if (mode == 'never') return false;
    if (mode == 'always') return true;

    // daily: solo la primera pausa del día por app
    final key = '$_askedPrefix$packageName';
    final today = _today();
    if (prefs.getString(key) == today) return false;
    await prefs.setString(key, today);
    return true;
  }
}