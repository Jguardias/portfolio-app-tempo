class AppRule {
  final String packageName;
  final bool isEnabled;
  final int initialThresholdMinutes;
  final int repeatIntervalMinutes;

  /// true = la pausa sale al abrir la app; false = tras un tiempo de uso.
  final bool triggerOnOpen;
  final DateTime? snoozedUntil;

  AppRule({
    required this.packageName,
    this.isEnabled = true,
    required this.initialThresholdMinutes,
    required this.repeatIntervalMinutes,
    this.triggerOnOpen = false,
    this.snoozedUntil,
  });

  AppRule copyWith({
    String? packageName,
    bool? isEnabled,
    int? initialThresholdMinutes,
    int? repeatIntervalMinutes,
    bool? triggerOnOpen,
    DateTime? snoozedUntil,
  }) {
    return AppRule(
      packageName: packageName ?? this.packageName,
      isEnabled: isEnabled ?? this.isEnabled,
      initialThresholdMinutes:
          initialThresholdMinutes ?? this.initialThresholdMinutes,
      repeatIntervalMinutes: repeatIntervalMinutes ?? this.repeatIntervalMinutes,
      triggerOnOpen: triggerOnOpen ?? this.triggerOnOpen,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
    );
  }
}