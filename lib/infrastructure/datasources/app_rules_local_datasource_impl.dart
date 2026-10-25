import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tempo/domain/datasources/app_rules_datasource.dart';
import 'package:tempo/domain/entities/app_rule.dart';
import 'package:tempo/infrastructure/mappers/app_rule_mapper.dart';
import 'package:tempo/infrastructure/models/app_rule_model.dart';
import 'package:tempo/config/helpers/tempo_log.dart';

class AppRulesLocalDatasourceImpl implements AppRulesDatasource {
  // Formato anterior: un único JSON con todas las reglas (se migra solo).
  static const String _legacyKeyRules = 'tempo_app_rules';

  // Formato nuevo: una clave por regla y una por snooze.
  static const String _rulePrefix = 'tempo_rule_';
  static const String _snoozePrefix = 'tempo_snooze_';

  /// Obtiene preferencias recargadas desde disco (UI, servicio y overlay son
  /// isolates distintos) y migra el formato viejo si existe.
  Future<SharedPreferences> _prefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    await _migrateLegacyIfNeeded(prefs);
    return prefs;
  }

  Future<void> _migrateLegacyIfNeeded(SharedPreferences prefs) async {
    final legacy = prefs.getString(_legacyKeyRules);
    if (legacy == null || legacy.isEmpty) return;

    try {
      final map = Map<String, dynamic>.from(jsonDecode(legacy) as Map);
      for (final entry in map.entries) {
        final ruleKey = '$_rulePrefix${entry.key}';
        if (prefs.containsKey(ruleKey)) continue; // no pisar datos nuevos

        final raw = entry.value;
        final Map<String, dynamic> json = raw is String
            ? jsonDecode(raw) as Map<String, dynamic>
            : Map<String, dynamic>.from(raw as Map);

        final model = AppRuleModel.fromJson(json);
        await prefs.setString(ruleKey, jsonEncode(_configOnlyJson(model)));

        if (model.snoozedUntil != null) {
          await prefs.setString(
            '$_snoozePrefix${entry.key}',
            model.snoozedUntil!.toIso8601String(),
          );
        }
      }
    } catch (e) {
      tempoLog("[Tempo Rules] Error migrando reglas antiguas: $e");
    }

    await prefs.remove(_legacyKeyRules);
  }

  Map<String, dynamic> _configOnlyJson(AppRuleModel model) {
    return AppRuleModel(
      packageName: model.packageName,
      isEnabled: model.isEnabled,
      initialThresholdMinutes: model.initialThresholdMinutes,
      repeatIntervalMinutes: model.repeatIntervalMinutes,
    ).toJson();
  }

  AppRule? _buildRule(SharedPreferences prefs, String packageName) {
    final raw = prefs.getString('$_rulePrefix$packageName');
    if (raw == null || raw.isEmpty) return null;

    try {
      final model =
          AppRuleModel.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
      final base = AppRuleMapper.toEntity(model);

      final snoozeRaw = prefs.getString('$_snoozePrefix$packageName');
      final snooze = snoozeRaw == null ? null : DateTime.tryParse(snoozeRaw);

      return AppRule(
        packageName: base.packageName,
        isEnabled: base.isEnabled,
        initialThresholdMinutes: base.initialThresholdMinutes,
        repeatIntervalMinutes: base.repeatIntervalMinutes,
        snoozedUntil: snooze,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveRule(AppRule rule) async {
    final prefs = await _prefs();

    // Se guarda SOLO la configuración. El snooze tiene su propia clave y lo
    // escribe únicamente saveSnooze, así que nunca se pisa desde la UI.
    final model = AppRuleMapper.toModel(AppRule(
      packageName: rule.packageName,
      isEnabled: rule.isEnabled,
      initialThresholdMinutes: rule.initialThresholdMinutes,
      repeatIntervalMinutes: rule.repeatIntervalMinutes,
    ));

    await prefs.setString(
      '$_rulePrefix${rule.packageName}',
      jsonEncode(model.toJson()),
    );
    tempoLog("[Tempo Rules] Regla guardada para ${rule.packageName}.");
  }

  @override
  Future<void> saveSnooze(String packageName, DateTime snoozedUntil) async {
    final prefs = await _prefs();
    await prefs.setString(
      '$_snoozePrefix$packageName',
      snoozedUntil.toIso8601String(),
    );
    tempoLog("[Tempo Rules] Snooze guardado para $packageName hasta $snoozedUntil.");
  }

  @override
  Future<AppRule?> getRuleForPackage(String packageName) async {
    final prefs = await _prefs();
    return _buildRule(prefs, packageName);
  }

  @override
  Future<Map<String, AppRule>> getRules() async {
    final prefs = await _prefs();

    final Map<String, AppRule> rules = {};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_rulePrefix)) continue;
      final packageName = key.substring(_rulePrefix.length);
      final rule = _buildRule(prefs, packageName);
      if (rule != null) rules[packageName] = rule;
    }
    return rules;
  }
}