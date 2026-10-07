import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/domain/datasources/app_rules_datasource.dart';
import 'package:tempo/infrastructure/datasources/app_rules_local_datasource_impl.dart';

final appRulesDatasourceProvider = Provider<AppRulesDatasource>((ref) {
  return AppRulesLocalDatasourceImpl();
});