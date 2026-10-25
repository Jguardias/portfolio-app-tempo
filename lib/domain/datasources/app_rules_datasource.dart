import 'package:tempo/domain/entities/app_rule.dart';

abstract class AppRulesDatasource {
  /// Guarda la configuración de la regla. NO modifica el snooze.
  Future<void> saveRule(AppRule rule);

  /// Guarda solo la pausa (snooze) de una app, sin tocar su configuración.
  Future<void> saveSnooze(String packageName, DateTime snoozedUntil);

  Future<AppRule?> getRuleForPackage(String packageName);
  Future<Map<String, AppRule>> getRules();
}