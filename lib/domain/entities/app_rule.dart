class AppRule {
  final String packageName;
  final bool isEnabled;
  final int initialThresholdMinutes;
  final int repeatIntervalMinutes;
  final DateTime? snoozedUntil;

  AppRule({
    required this.packageName,
    this.isEnabled = true,
    required this.initialThresholdMinutes,
    required this.repeatIntervalMinutes,
    this.snoozedUntil,
  });

  AppRule copyWith({
    String? packageName,
    bool? isEnabled,
    int? initialThresholdMinutes,
    int? repeatIntervalMinutes,
    DateTime? snoozedUntil,
  }) {
    return AppRule(
      packageName: packageName ?? this.packageName,
      isEnabled: isEnabled ?? this.isEnabled,
      initialThresholdMinutes: initialThresholdMinutes ?? this.initialThresholdMinutes,
      repeatIntervalMinutes: repeatIntervalMinutes ?? this.repeatIntervalMinutes,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
    );
  }
}