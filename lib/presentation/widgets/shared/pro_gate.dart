import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/config/constants/pro_config.dart';
import 'package:tempo/config/theme/app_theme.dart';
import 'package:tempo/presentation/providers/appRules/app_rules_provider.dart';
import 'package:tempo/presentation/providers/settings/pro_provider.dart';

/// true si se puede activar la pausa para esta app (Pro, o dentro del límite gratis).
/// Si no, muestra la pantalla de Tempo Pro y devuelve el resultado.
Future<bool> ensureCanEnable(
  BuildContext context,
  WidgetRef ref,
  String packageName,
) async {
  if (ref.read(isProProvider)) return true;

  final rules = ref.read(appRulesProvider);
  if (rules[packageName]?.isEnabled ?? false) return true;

  final enabledCount = rules.values.where((r) => r.isEnabled).length;
  if (enabledCount < ProConfig.freeAppLimit) return true;

  await showProPaywall(
    context,
    ref,
    reason:
        "La versión gratuita permite la pausa en ${ProConfig.freeAppLimit} apps a la vez.",
  );
  return ref.read(isProProvider);
}

Future<void> showProPaywall(
  BuildContext context,
  WidgetRef ref, {
  required String reason,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final primary = Theme.of(sheetContext).colorScheme.primary;

      Widget benefit(String text) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 20, color: primary),
                const SizedBox(width: 10),
                Expanded(child: Text(text)),
              ],
            ),
          );

      return Container(
        decoration: BoxDecoration(
          color: AppTheme.getBackgroundColor(sheetContext),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.workspace_premium_rounded, size: 40, color: primary),
                const SizedBox(height: 12),
                const Text(
                  "Tempo Pro",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(reason,
                    style: const TextStyle(color: AppTheme.textSegundary)),
                const SizedBox(height: 16),
                benefit("Pausa en todas las apps que quieras (gratis: hasta ${ProConfig.freeAppLimit})"),
                benefit("Resumen de tus motivos: qué respondes más y en qué apps"),
                benefit("Un solo pago, sin suscripción"),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: kDebugMode
                        ? () {
                            ref.read(isProProvider.notifier).setPro(true);
                            Navigator.of(sheetContext).maybePop();
                          }
                        : null,
                    child: Text(kDebugMode
                        ? "Activar Pro (solo pruebas)"
                        : "Disponible pronto"),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    child: const Text("Ahora no"),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}