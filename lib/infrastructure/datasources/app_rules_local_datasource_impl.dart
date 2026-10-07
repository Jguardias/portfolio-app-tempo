import 'dart:convert'; 
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tempo/domain/datasources/app_rules_datasource.dart';
import 'package:tempo/domain/entities/app_rule.dart';
import 'package:tempo/infrastructure/mappers/app_rule_mapper.dart';
import 'package:tempo/infrastructure/models/app_rule_model.dart';

class AppRulesLocalDatasourceImpl implements AppRulesDatasource {
  static const String _keyRules = 'tempo_app_rules';

  @override
  Future<void> saveRule(AppRule rule) async {
    final prefs = await SharedPreferences.getInstance();
    final rulesMap = await _getAllRawRules(prefs);

    final model = AppRuleMapper.toModel(rule);
    rulesMap[rule.packageName] = model.toJson();

    await prefs.setString(_keyRules, jsonEncode(rulesMap));
  }

  @override
  Future<AppRule?> getRuleForPackage(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    final rulesMap = await _getAllRawRules(prefs);

    if (rulesMap.containsKey(packageName)) {
      final rawData = rulesMap[packageName];
      final Map<String, dynamic> json = rawData is String
          ? jsonDecode(rawData)
          : Map<String, dynamic>.from(rawData as Map);

      final model = AppRuleModel.fromJson(json);
      return AppRuleMapper.toEntity(model);
    }
    return null;
  }

  @override
  Future<Map<String, AppRule>> getRules() async {
    final prefs = await SharedPreferences.getInstance();
    final rulesMap = await _getAllRawRules(prefs);

    final Map<String, AppRule> rules = {};
    rulesMap.forEach((key, value) {
      final Map<String, dynamic> json = value is String
          ? jsonDecode(value)
          : Map<String, dynamic>.from(value as Map);

      final model = AppRuleModel.fromJson(json);
      rules[key] = AppRuleMapper.toEntity(model);
    });

    return rules;
  }

  Future<Map<String, dynamic>> _getAllRawRules(SharedPreferences prefs) async {
    // OBLIGATORIO: Forzar la recarga desde disco para que los Isolates
    // (UI y servicio en segundo plano) compartan siempre los datos actualizados.
    await prefs.reload();

    final jsonString = prefs.getString(_keyRules);
    if (jsonString == null || jsonString.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(jsonString) as Map);
    } catch (_) {
      return {};
    }
  }
}