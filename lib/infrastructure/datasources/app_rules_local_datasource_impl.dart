import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tempo/domain/datasources/app_rules_datasource.dart';
import 'package:tempo/domain/entities/app_rule.dart';
import 'package:tempo/infrastructure/mappers/app_rule_mapper.dart';
import 'package:tempo/infrastructure/models/app_rule_model.dart';

class AppRulesLocalDatasourceImpl implements AppRulesDatasource {
  // Una clave por regla y una por pausa (snooze): la UI y el servicio nunca se pisan.
  static const String _rulePrefix = 'tempo_rule_';
  static const String _snoozePrefix = 'tempo_snooze_';

  Future<SharedPreferences> _prefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs;
  }

  AppRule? _buildRule(SharedPreferences prefs, String packageName) {
    final raw = prefs.getString('$_rulePrefix$packageName');
    if (raw == null || raw.isEmpty) return null;

    try {
      final model = AppRuleModel.fromJson(
          Map<String, dynamic>.from(jsonDecode(raw) as Map));
      final base = AppRuleMapper.toEntity(model);
      final snoozeRaw = prefs.getString('$_snoozePrefix$packageName');
      final snooze = snoozeRaw == null ? null : DateTime.tryParse(snoozeRaw);

      return AppRule(
        packageName: base.packageName,
        isEnabled: base.isEnabled,
        initialThresholdMinutes: base.initialThresholdMinutes,
        repeatIntervalMinutes: base.repeatIntervalMinutes,
        triggerOnOpen: base.triggerOnOpen,
        snoozedUntil: snooze,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveRule(AppRule rule) async {
    final prefs = await _prefs();

    // Solo la configuración; el snooze lo escribe únicamente saveSnooze.
    final model = AppRuleMapper.toModel(AppRule(
      packageName: rule.packageName,
      isEnabled: rule.isEnabled,
      initialThresholdMinutes: rule.initialThresholdMinutes,
      repeatIntervalMinutes: rule.repeatIntervalMinutes,
      triggerOnOpen: rule.triggerOnOpen,
    ));

    await prefs.setString(
      '$_rulePrefix${rule.packageName}',
      jsonEncode(model.toJson()),
    );
  }

  @override
  Future<void> saveSnooze(String packageName, DateTime snoozedUntil) async {
    final prefs = await _prefs();
    await prefs.setString(
      '$_snoozePrefix$packageName',
      snoozedUntil.toIso8601String(),
    );
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