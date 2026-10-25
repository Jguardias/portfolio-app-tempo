import 'package:tempo/domain/entities/app_rule.dart';

abstract class AppRulesRepository {
  Future<void> saveRule(AppRule rule);
  Future<void> saveSnooze(String packageName, DateTime snoozedUntil);
  Future<AppRule?> getRuleForPackage(String packageName);
  Future<Map<String, AppRule>> getRules();
}