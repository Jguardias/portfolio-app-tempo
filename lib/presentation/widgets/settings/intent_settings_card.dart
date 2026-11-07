import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/config/theme/app_theme.dart';
import 'package:tempo/presentation/providers/settings/intent_mode_provider.dart';

class IntentSettingsCard extends ConsumerWidget {
  const IntentSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(intentModeProvider);

    final String detail = switch (mode) {
      IntentMode.always => 'Te lo preguntamos en todas las pausas.',
      IntentMode.daily => 'Solo en la primera pausa del día de cada app.',
      IntentMode.never => 'No te preguntamos. Las pausas se guardan sin motivo.',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(
              'Pausa',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSegundary,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.getTileColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.getBorderColor(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Preguntarme para qué uso la app',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                const Text(
                  'En cada pausa puedes decir, si quieres, para qué usas la app. '
                  'Es opcional y se guarda solo en tu teléfono.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSegundary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<IntentMode>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                          value: IntentMode.always, label: Text('Siempre')),
                      ButtonSegment(
                          value: IntentMode.daily, label: Text('1 al día')),
                      ButtonSegment(
                          value: IntentMode.never, label: Text('Nunca')),
                    ],
                    selected: {mode},
                    onSelectionChanged: (s) =>
                        ref.read(intentModeProvider.notifier).setMode(s.first),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  detail,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}