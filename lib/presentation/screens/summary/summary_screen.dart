import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/config/theme/app_theme.dart';
import 'package:tempo/presentation/providers/settings/pro_provider.dart';
import 'package:tempo/presentation/providers/summary/summary_calculator.dart';
import 'package:tempo/presentation/providers/summary/summary_provider.dart';
import 'package:tempo/presentation/widgets/shared/pro_gate.dart';

class SummaryScreen extends ConsumerStatefulWidget {
  static const name = 'summary-screen';

  const SummaryScreen({super.key});

  @override
  ConsumerState<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends ConsumerState<SummaryScreen> {
  String _mode = 'all'; // all | open | time

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(pauseEventsProvider);
    final isPro = ref.watch(isProProvider);

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.getBackgroundColor(context),
        title: const Text('Tus motivos'),
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (events) {
          final summary = SummaryCalculator.compute(
            events,
            DateTime.now(),
            mode: _mode == 'all' ? null : _mode,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Esto es lo que Tempo registró en tus pausas de los últimos 7 días. Se guarda solo en tu teléfono y refleja lo que tú indicaste; Tempo no adivina tus intenciones.\n\n'
                '• Al abrir: pausas que salieron justo al abrir una app.\n'
                '• Por tiempo: pausas que salieron por tu tiempo de uso.',
                style: TextStyle(color: AppTheme.textSegundary, height: 1.4),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('Todas')),
                    ButtonSegment(value: 'open', label: Text('Al abrir')),
                    ButtonSegment(value: 'time', label: Text('Por tiempo')),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => setState(() => _mode = s.first),
                ),
              ),
              const SizedBox(height: 16),
              if (summary.isEmpty)
                const _Box(
                  child: Text(
                    'Aún no hay pausas registradas en este periodo. Cuando Tempo te muestre pausas, aquí verás lo que fuiste respondiendo.',
                    style: TextStyle(height: 1.4),
                  ),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        icon: Icons.pause_circle_outline_rounded,
                        value: '${summary.totalPauses}',
                        label: 'Pausas mostradas',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Stat(
                        icon: Icons.exit_to_app_rounded,
                        value: '${summary.exits}',
                        label: 'Veces que saliste de la app tras una pausa',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Salir de la app no significa necesariamente que evitaste un impulso; es solo lo que hiciste después de ver la pausa.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSegundary),
                ),                
                const SizedBox(height: 16),
                if (isPro) ...[
                  _IntentBars(summary: summary),
                  const SizedBox(height: 16),
                  _AppsList(summary: summary),
                ] else
                  _Box(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.lock_outline_rounded),
                            SizedBox(width: 8),
                            Text('Resumen de motivos',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Con Tempo Pro ves qué motivos indicas más y qué apps te piden más pausas.',
                          style: TextStyle(height: 1.4),
                        ),
                        const SizedBox(height: 12),
                        FilledButton.tonal(
                          onPressed: () => showProPaywall(
                            context,
                            ref,
                            reason: 'El resumen de motivos es parte de Tempo Pro.',
                          ),
                          child: const Text('Ver Tempo Pro'),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _Box extends StatelessWidget {
  final Widget child;

  const _Box({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getTileColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: child,
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _Stat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return _Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primary),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w800, color: primary)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSegundary)),
        ],
      ),
    );
  }
}

class _IntentBars extends StatelessWidget {
  final PauseSummary summary;

  const _IntentBars({required this.summary});

  @override
  Widget build(BuildContext context) {
    final entries = SummaryCalculator.intentLabels.entries
        .where((e) => (summary.intents[e.key] ?? 0) > 0)
        .toList();
    final maxCount = entries.isEmpty
        ? 1
        : entries
            .map((e) => summary.intents[e.key]!)
            .reduce((a, b) => a > b ? a : b);
    final unanswered = summary.totalPauses - summary.answered;

    return _Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tus motivos',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const Text('Todavía no has indicado ningún motivo.')
          else
            for (final e in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(e.value)),
                        Text('${summary.intents[e.key]}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: summary.intents[e.key]! / maxCount,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(4),
                      backgroundColor: AppTheme.getBorderColor(context),
                    ),
                  ],
                ),
              ),
          if (unanswered > 0)
            Text('Sin responder: $unanswered',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textSegundary)),
        ],
      ),
    );
  }
}

class _AppsList extends StatelessWidget {
  final PauseSummary summary;

  const _AppsList({required this.summary});

  @override
  Widget build(BuildContext context) {
    final apps = summary.apps.take(8).toList();
    return _Box(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Por aplicación',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final app in apps) _AppRow(app: app),
        ],
      ),
    );
  }
}

class _AppRow extends ConsumerWidget {
  final AppSummary app;

  const _AppRow({required this.app});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref
        .watch(appNameProvider(app.packageName))
        .maybeWhen(data: (n) => n, orElse: () => app.packageName);
    final top = app.topIntent;
    final topLabel = top == null ? null : SummaryCalculator.intentLabels[top];

    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${app.pauses} pausas · ${app.exits} salidas'
        '${topLabel != null ? ' · $topLabel' : ''}',
      ),
    );
  }
}