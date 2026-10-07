import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/domain/repositories/app_rules_repository.dart';
import 'package:tempo/infrastructure/repositories/app_rules_repository_impl.dart';
import 'app_rules_provider_datasource.dart';

final appRulesRepositoryProvider = Provider<AppRulesRepository>((ref) {
  final datasource = ref.watch(appRulesDatasourceProvider);
  return AppRulesRepositoryImpl(datasource);
});