import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/domain/entities/app_rule.dart';
import 'package:tempo/domain/repositories/app_rules_repository.dart';
import 'app_rules_provider_repository.dart';

class AppRulesNotifier extends StateNotifier<Map<String, AppRule>> {
  final AppRulesRepository repository;

  AppRulesNotifier(this.repository) : super({});

  /// Guarda una regla en SharedPreferences y actualiza el estado de Riverpod
  Future<void> saveRule(AppRule rule) async {
    await repository.saveRule(rule);
    state = {
      ...state,
      rule.packageName: rule,
    };
  }

  /// Carga y retorna la regla de un paquete específico
  Future<AppRule?> getRuleForPackage(String packageName) async {
    if (state.containsKey(packageName)) {
      return state[packageName];
    }

    final rule = await repository.getRuleForPackage(packageName);
    if (rule != null) {
      state = {
        ...state,
        packageName: rule,
      };
    }
    return rule;
  }
}

final appRulesProvider = StateNotifierProvider<AppRulesNotifier, Map<String, AppRule>>((ref) {
  final repository = ref.watch(appRulesRepositoryProvider);
  return AppRulesNotifier(repository);
});