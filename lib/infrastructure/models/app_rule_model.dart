class AppRuleModel {
  final String packageName;
  final bool isEnabled;
  final int initialThresholdMinutes;
  final int repeatIntervalMinutes;
  final bool triggerOnOpen;
  final DateTime? snoozedUntil;

  AppRuleModel({
    required this.packageName,
    required this.isEnabled,
    required this.initialThresholdMinutes,
    required this.repeatIntervalMinutes,
    this.triggerOnOpen = false,
    this.snoozedUntil,
  });

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'isEnabled': isEnabled,
      'initialThresholdMinutes': initialThresholdMinutes,
      'repeatIntervalMinutes': repeatIntervalMinutes,
      'triggerOnOpen': triggerOnOpen,
      'snoozedUntil': snoozedUntil?.toIso8601String(),
    };
  }

  factory AppRuleModel.fromJson(Map<String, dynamic> json) {
    return AppRuleModel(
      packageName: json['packageName'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
      initialThresholdMinutes: json['initialThresholdMinutes'] as int? ?? 30,
      repeatIntervalMinutes: json['repeatIntervalMinutes'] as int? ?? 10,
      triggerOnOpen: json['triggerOnOpen'] as bool? ?? false,
      snoozedUntil: json['snoozedUntil'] != null
          ? DateTime.parse(json['snoozedUntil'] as String)
          : null,
    );
  }
}