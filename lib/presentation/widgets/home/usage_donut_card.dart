import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/config/helpers/duration_format.dart';
import 'package:tempo/config/theme/app_theme.dart';
import 'package:tempo/domain/entities/app_usage.dart';
import 'package:tempo/presentation/providers/settings/pro_provider.dart';
import 'package:tempo/presentation/widgets/shared/pro_gate.dart';

class UsageDonutCard extends ConsumerWidget {
  final List<AppUsage> apps;

  const UsageDonutCard({super.key, required this.apps});

  static const List<Color> _palette = [
    Color(0xFF4285F4),
    Color(0xFFEA4335),
    Color(0xFF34A853),
    Color(0xFFFBBC04),
  ];
  static const Color _otherColor = Color(0xFF9AA0A6);
  static const int _maxSegments = 4;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.getTileColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.getBorderColor(context)),
        ),
        child: isPro ? _chart(context) : _locked(context, ref),
      ),
    );
  }

  Widget _locked(BuildContext context, WidgetRef ref) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.donut_large_rounded, color: primary),
            const SizedBox(width: 8),
            const Text('Gráfico de tu día',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            const Icon(Icons.lock_outline_rounded,
                size: 18, color: AppTheme.textSegundary),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Con Tempo Pro ves cómo se reparte tu tiempo de hoy entre tus apps.',
          style: TextStyle(height: 1.4),
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: () => showProPaywall(
            context,
            ref,
            reason: 'El gráfico de tu día es parte de Tempo Pro.',
          ),
          child: const Text('Ver Tempo Pro'),
        ),
      ],
    );
  }

  Widget _chart(BuildContext context) {
    final used = apps.where((a) => a.totalTimeInForeground.inSeconds > 0).toList()
      ..sort(
          (a, b) => b.totalTimeInForeground.compareTo(a.totalTimeInForeground));
    final totalMs = used.fold<int>(
        0, (sum, a) => sum + a.totalTimeInForeground.inMilliseconds);

    if (totalMs == 0) {
      return const Text(
        'Aún no hay uso registrado hoy. Cuando uses tu teléfono, aquí verás cómo se reparte tu tiempo.',
        style: TextStyle(height: 1.4),
      );
    }

    final top = used.take(_maxSegments).toList();
    final restMs = used.skip(_maxSegments).fold<int>(
        0, (sum, a) => sum + a.totalTimeInForeground.inMilliseconds);

    final segments = <_Segment>[
      for (var i = 0; i < top.length; i++)
        _Segment(
          name: top[i].appName ?? top[i].packageName,
          ms: top[i].totalTimeInForeground.inMilliseconds,
          color: _palette[i],
        ),
      if (restMs > 0) _Segment(name: 'Otras', ms: restMs, color: _otherColor),
    ];

    return Column(
      children: [
        SizedBox(
          width: 190,
          height: 190,
          child: CustomPaint(
            painter: _DonutPainter(
              fractions: segments.map((s) => s.ms / totalMs).toList(),
              colors: segments.map((s) => s.color).toList(),
              trackColor: AppTheme.getBorderColor(context),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('HOY',
                      style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 1.2,
                          color: AppTheme.textSegundary)),
                  const SizedBox(height: 4),
                  Text(
                    formatDuration(Duration(milliseconds: totalMs)),
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final s in segments)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration:
                      BoxDecoration(color: s.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(s.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Text(
                  formatDuration(Duration(milliseconds: s.ms)),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 38,
                  child: Text(
                    '${(s.ms / totalMs * 100).round()}%',
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textSegundary),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        const Text(
          'Incluye solo las apps que Tempo puede monitorear, así que el total puede diferir del de Bienestar Digital.',
          style: TextStyle(fontSize: 11, color: AppTheme.textSegundary),
        ),
      ],
    );
  }
}

class _Segment {
  final String name;
  final int ms;
  final Color color;

  const _Segment({required this.name, required this.ms, required this.color});
}

class _DonutPainter extends CustomPainter {
  final List<double> fractions;
  final List<Color> colors;
  final Color trackColor;

  _DonutPainter({
    required this.fractions,
    required this.colors,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const double stroke = 18;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = trackColor,
    );

    const double gap = 0.05;
    final bool single = fractions.length == 1;
    double start = -math.pi / 2;

    for (var i = 0; i < fractions.length; i++) {
      final sweep = fractions[i] * 2 * math.pi;
      final drawn = single ? sweep : math.max(sweep - gap, 0.02);
      canvas.drawArc(
        rect,
        start + (single ? 0 : gap / 2),
        drawn,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.butt
          ..color = colors[i],
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => true;
}