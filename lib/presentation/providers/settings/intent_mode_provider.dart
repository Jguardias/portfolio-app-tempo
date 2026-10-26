import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum IntentMode { always, daily, never }

class IntentModeNotifier extends StateNotifier<IntentMode> {
  // Debe coincidir con la clave que lee PauseEventStore.
  static const String _key = 'tempo_intent_mode';

  IntentModeNotifier() : super(IntentMode.always) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getString(_key);
      state = IntentMode.values.firstWhere(
        (m) => m.name == value,
        orElse: () => IntentMode.always,
      );
    } catch (_) {}
  }

  Future<void> setMode(IntentMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {}
  }
}

final intentModeProvider =
    StateNotifierProvider<IntentModeNotifier, IntentMode>(
        (ref) => IntentModeNotifier());