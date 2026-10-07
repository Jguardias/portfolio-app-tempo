import 'package:tempo/domain/entities/app_rule.dart';

abstract class AppRulesRepository {
  Future<void> saveRule(AppRule rule);
  Future<AppRule?> getRuleForPackage(String packageName);
}