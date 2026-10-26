import 'package:flutter_test/flutter_test.dart';
import 'package:tempo/infrastructure/services/pause_event_store.dart';
import 'package:tempo/presentation/providers/summary/summary_calculator.dart';

PauseEvent _e(
  DateTime t, {
  String pkg = 'a',
  String mode = 'time',
  String? intent,
  String action = 'continue',
}) =>
    PauseEvent(
      time: t.millisecondsSinceEpoch,
      packageName: pkg,
      mode: mode,
      intent: intent,
      action: action,
    );

void main() {
  final now = DateTime(2026, 10, 26, 12);

  test('cuenta pausas, salidas y motivos', () {
    final s = SummaryCalculator.compute([
      _e(now, intent: 'habit', action: 'exit'),
      _e(now, intent: 'habit'),
      _e(now, pkg: 'b', action: 'left'),
    ], now);

    expect(s.totalPauses, 3);
    expect(s.exits, 2);
    expect(s.answered, 2);
    expect(s.intents['habit'], 2);
    expect(s.apps.first.packageName, 'a');
  });

  test('ignora eventos de hace más de 7 días', () {
    final s = SummaryCalculator.compute(
      [_e(now.subtract(const Duration(days: 8)))],
      now,
    );
    expect(s.isEmpty, true);
  });

  test('filtra por modo', () {
    final s = SummaryCalculator.compute(
      [_e(now, mode: 'open'), _e(now, mode: 'time')],
      now,
      mode: 'open',
    );
    expect(s.totalPauses, 1);
  });
}