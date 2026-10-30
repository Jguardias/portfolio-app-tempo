import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/config/constants/pro_config.dart';
import 'package:tempo/config/theme/app_theme.dart';
import 'package:tempo/presentation/providers/appRules/app_rules_provider.dart';
import 'package:tempo/presentation/providers/settings/pro_provider.dart';
import 'package:tempo/presentation/providers/settings/purchase_provider.dart';

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
    builder: (_) => _PaywallSheet(reason: reason),
  );
}

class _PaywallSheet extends ConsumerWidget {
  final String reason;

  const _PaywallSheet({required this.reason});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    final purchase = ref.watch(purchaseProvider);
    final isPro = ref.watch(isProProvider);

    // Al activarse Pro, la hoja se cierra sola
    ref.listen<bool>(isProProvider, (previous, next) {
      if (next && previous == false) {
        Navigator.of(context).maybePop();
      }
    });

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

    final bool busy = purchase.status == StoreStatus.loading ||
        purchase.status == StoreStatus.purchasing;
    final bool canBuy = purchase.status == StoreStatus.ready && !isPro;

    final String buttonText = switch (purchase.status) {
      StoreStatus.ready => purchase.price != null
          ? "Desbloquear por ${purchase.price}"
          : "Desbloquear",
      StoreStatus.unavailable => "No disponible por ahora",
      _ => "",
    };

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getBackgroundColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
              benefit(
                  "Pausa en todas las apps que quieras (gratis: hasta ${ProConfig.freeAppLimit})"),
              benefit("Resumen de tus motivos: qué respondes más y en qué apps"),
              benefit("Un solo pago, sin suscripción"),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: canBuy
                      ? () => ref.read(purchaseProvider.notifier).buy()
                      : null,
                  child: busy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Text(buttonText),
                ),
              ),
              if (purchase.message != null) ...[
                const SizedBox(height: 10),
                Text(
                  purchase.message!,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSegundary),
                ),
              ],
              Center(
                child: TextButton(
                  onPressed: busy
                      ? null
                      : () => ref.read(purchaseProvider.notifier).restore(),
                  child: const Text("Restaurar compra"),
                ),
              ),
              if (kDebugMode)
                Center(
                  child: TextButton(
                    onPressed: () =>
                        ref.read(isProProvider.notifier).setPro(true),
                    child: const Text("Activar Pro (solo pruebas)"),
                  ),
                ),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text("Ahora no"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}