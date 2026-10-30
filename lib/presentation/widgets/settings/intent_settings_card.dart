import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/config/theme/app_theme.dart';
import 'package:tempo/presentation/providers/settings/intent_mode_provider.dart';

class IntentSettingsCard extends ConsumerWidget {
  const IntentSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(intentModeProvider);
    final primary = Theme.of(context).colorScheme.primary;

    Widget option(IntentMode m, String title, String text) {
      final selected = mode == m;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: selected ? primary : AppTheme.textSegundary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$title: ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: text),
                  ],
                ),
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ),
          ],
        ),
      );
    }

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
                const SizedBox(height: 8),
                const Text(
                  'Cuando Tempo te muestra una pausa, puede hacerte una pregunta opcional: '
                  '"¿Para qué estás usando esta app?", con algunas opciones para elegir. '
                  'No es obligatoria: puedes ignorarla y seguir. Lo que respondas se guarda '
                  'solo en tu teléfono y alimenta el resumen "Tus motivos".\n\n'
                  'Aquí eliges cada cuánto quieres que aparezca esa pregunta:',
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
                          value: IntentMode.daily, label: Text('1.ª del día')),
                      ButtonSegment(
                          value: IntentMode.never, label: Text('Nunca')),
                    ],
                    selected: {mode},
                    onSelectionChanged: (s) =>
                        ref.read(intentModeProvider.notifier).setMode(s.first),
                  ),
                ),
                const SizedBox(height: 14),
                option(IntentMode.always, 'Siempre',
                    'la pregunta aparece en todas las pausas.'),
                option(IntentMode.daily, '1.ª del día',
                    'solo en la primera pausa del día de cada app. En las demás pausas del mismo día no te preguntamos.'),
                option(IntentMode.never, 'Nunca',
                    'no te preguntamos nunca. Las pausas se guardan sin motivo.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}