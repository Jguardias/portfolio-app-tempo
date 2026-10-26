import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tempo/config/constants/pro_config.dart';

class ProNotifier extends StateNotifier<bool> {
  static const String _key = 'tempo_is_pro';

  ProNotifier() : super(ProConfig.unlockedForTesting) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getBool(_key);
      if (kDebugMode && stored != null) {
        state = stored; // en debug manda el interruptor de Ajustes
      } else {
        state = ProConfig.unlockedForTesting || (stored ?? false);
      }
    } catch (_) {}
  }

  Future<void> setPro(bool value) async {
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (_) {}
  }
}

final isProProvider =
    StateNotifierProvider<ProNotifier, bool>((ref) => ProNotifier());