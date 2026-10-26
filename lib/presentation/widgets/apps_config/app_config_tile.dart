import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/config/theme/app_theme.dart';
import 'package:tempo/domain/entities/app_rule.dart';
import 'package:tempo/domain/entities/app_usage.dart';
import 'package:tempo/presentation/providers/appRules/app_rules_provider.dart';
import 'package:tempo/presentation/widgets/apps_config/app_limit_modal.dart';
import 'package:tempo/presentation/widgets/shared/pro_gate.dart';
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
        'triggerOnOpen': existingRule?.triggerOnOpen ?? false,
        'iconBytes': app.icon,
      }),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    // Solo se observa la regla de ESTA app (no todo el mapa)
    final AppRule? existingRule = ref.watch(
      appRulesProvider.select((rules) => rules[app.packageName]),
    );

    final isEnabled = existingRule?.isEnabled ?? false;
    final initialThresholdMinutes = existingRule?.initialThresholdMinutes ?? 30;
    final repeatIntervalMinutes = existingRule?.repeatIntervalMinutes ?? 10;
    final triggerOnOpen = existingRule?.triggerOnOpen ?? false;
    final tileColor = AppTheme.getTileColor(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isEnabled
              ? Color.alphaBlend(primaryColor.withValues(alpha: 0.06), tileColor)
              : tileColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled
                ? primaryColor.withValues(alpha: 0.5)
                : AppTheme.getBorderColor(context),
            width: isEnabled ? 1.5 : 1,
          ),
        ),
        child: ListTile(
          onTap: () => _openLimitModal(context, existingRule),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
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
              ? Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (triggerOnOpen) ...[
                        const _Pill(
                          icon: Icons.touch_app_outlined,
                          text: "Al abrir la app",
                        ),
                        _Pill(
                          icon: Icons.snooze_rounded,
                          text: "Descanso de $repeatIntervalMinutes min",
                        ),
                      ] else ...[
                        _Pill(
                          icon: Icons.timer_outlined,
                          text: "Aviso a los $initialThresholdMinutes min",
                        ),
                        _Pill(
                          icon: Icons.repeat_rounded,
                          text: "Cada $repeatIntervalMinutes min",
                        ),
                      ],
                    ],
                  ),
                )
              : const Text(
                  "Sin pausas activadas",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSegundary,
                  ),
                ),
          trailing: Switch(
            value: isEnabled,
               onChanged: (val) async {
              if (val && !await ensureCanEnable(context, ref, app.packageName)) {
                return;
              }
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
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Pill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }
}