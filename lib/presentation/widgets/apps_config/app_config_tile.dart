import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/config/theme/app_theme.dart';
import 'package:tempo/domain/entities/app_rule.dart';
import 'package:tempo/domain/entities/app_usage.dart';
import 'package:tempo/presentation/providers/appRules/app_rules_provider.dart';
import 'package:tempo/presentation/widgets/apps_config/app_limit_modal.dart';

class AppConfigTile extends ConsumerWidget {
  final AppUsage app;

  const AppConfigTile({super.key, required this.app});

  void _openLimitModal(BuildContext context, AppRule? existingRule) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppLimitModal(appData: {
        'appName': app.appName ?? app.packageName,
        'packageName': app.packageName,
        'isEnabled': existingRule?.isEnabled ?? false,
        'initialThresholdMinutes': existingRule?.initialThresholdMinutes ?? 30,
        'repeatIntervalMinutes': existingRule?.repeatIntervalMinutes ?? 10,
        'iconBytes': app.icon,
      }),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    // 1. Obtener las reglas guardadas desde Riverpod
    final rulesMap = ref.watch(appRulesProvider);
    final AppRule? existingRule = rulesMap[app.packageName];

    // Si existe la regla, usar sus datos; de lo contrario, usar valores por defecto
    final isEnabled = existingRule?.isEnabled ?? false;
    final initialThresholdMinutes = existingRule?.initialThresholdMinutes ?? 30;
    final repeatIntervalMinutes = existingRule?.repeatIntervalMinutes ?? 10;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isEnabled ? 1.0 : 0.55,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.getTileColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.getBorderColor(context)),
          ),
          child: ListTile(
            onTap: () => _openLimitModal(context, existingRule),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            leading: app.icon != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      app.icon!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    Icons.apps,
                    size: 40,
                    color: primaryColor,
                  ),
            title: Text(
              app.appName ?? app.packageName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: isEnabled
                ? Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 13, color: AppTheme.textSegundary),
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(Icons.timer_outlined, size: 14, color: primaryColor),
                        ),
                        const TextSpan(text: " Aviso: "),
                        TextSpan(
                          text: "${initialThresholdMinutes}m",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const TextSpan(text: "   •   "),
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Icon(Icons.repeat_rounded, size: 14, color: primaryColor),
                        ),
                        const TextSpan(text: " Repite: "),
                        TextSpan(
                          text: "c/${repeatIntervalMinutes}m",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : const Text(
                    "Monitoreo desactivado",
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSegundary,
                    ),
                  ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Switch(
                  value: isEnabled,
                  onChanged: (val) {
                    // 2. Guardar el cambio inmediatamente en SharedPreferences a través de Riverpod
                    final updatedRule = (existingRule ??
                            AppRule(
                              packageName: app.packageName,
                              isEnabled: val,
                              initialThresholdMinutes: 30,
                              repeatIntervalMinutes: 10,
                            ))
                        .copyWith(isEnabled: val);

                    ref.read(appRulesProvider.notifier).saveRule(updatedRule);
                  },
                ),
                const SizedBox(width: 2),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.textSegundary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}