import 'package:tempo/domain/entities/app_rule.dart';

abstract class AppRulesDatasource {
  Future<void> saveRule(AppRule rule);
  Future<AppRule?> getRuleForPackage(String packageName);
  Future<Map<String, AppRule>> getRules();
}