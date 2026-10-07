import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/domain/entities/app_rule.dart';
import 'package:tempo/presentation/providers/appRules/app_rules_provider.dart';

class AppLimitModal extends ConsumerStatefulWidget {
  final Map<String, dynamic> appData;

  const AppLimitModal({super.key, required this.appData});

  @override
  ConsumerState<AppLimitModal> createState() => _AppLimitModalState();
}

class _AppLimitModalState extends ConsumerState<AppLimitModal> {
  late double _initialMinutes;
  late double _repeatMinutes;

  final List<int> _initialPresets = [15, 30, 45, 60];
  final List<int> _repeatPresets = [5, 10, 15, 20];

  @override
  void initState() {
    super.initState();
    _initialMinutes = ((widget.appData['initialThresholdMinutes'] as int?) ?? 30).toDouble();
    _repeatMinutes = ((widget.appData['repeatIntervalMinutes'] as int?) ?? 10).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final appName = (widget.appData['appName'] as String?) ?? 'Aplicación';
    final packageName = widget.appData['packageName'] as String;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            "Configurar $appName",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Sección 1: Tiempo límite inicial
          Text(
            "Primer aviso tras: ${_initialMinutes.toInt()} minutos de uso",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _initialPresets.map((preset) {
              return ChoiceChip(
                label: Text("$preset min"),
                selected: _initialMinutes.toInt() == preset,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _initialMinutes = preset.toDouble());
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Sección 2: Frecuencia de repetición
          Text(
            "Si continúas usando, reinterrumpir cada: ${_repeatMinutes.toInt()} minutos",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _repeatPresets.map((preset) {
              return ChoiceChip(
                label: Text("$preset min"),
                selected: _repeatMinutes.toInt() == preset,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _repeatMinutes = preset.toDouble());
                  }
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 32),

          // Botón Guardar
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: () async {
                final newRule = AppRule(
                  packageName: packageName,
                  isEnabled: true, // Al guardar la regla desde el modal se activa
                  initialThresholdMinutes: _initialMinutes.toInt(),
                  repeatIntervalMinutes: _repeatMinutes.toInt(),
                );

                await ref.read(appRulesProvider.notifier).saveRule(newRule);

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: const Text("Guardar Regla"),
            ),
          ),
        ],
      ),
    );
  }
}