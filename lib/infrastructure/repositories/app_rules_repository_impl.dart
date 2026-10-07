import 'package:tempo/domain/datasources/app_rules_datasource.dart';
import 'package:tempo/domain/entities/app_rule.dart';
import 'package:tempo/domain/repositories/app_rules_repository.dart';

class AppRulesRepositoryImpl implements AppRulesRepository {
  final AppRulesDatasource datasource;

  AppRulesRepositoryImpl(this.datasource);

  @override
  Future<void> saveRule(AppRule rule) {
    return datasource.saveRule(rule);
  }

  @override
  Future<AppRule?> getRuleForPackage(String packageName) {
    return datasource.getRuleForPackage(packageName);
  }
}