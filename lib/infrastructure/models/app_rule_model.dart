class AppRuleModel {
  final String packageName;
  final bool isEnabled;
  final int initialThresholdMinutes;
  final int repeatIntervalMinutes;
  final String? snoozedUntil;

  AppRuleModel({
    required this.packageName,
    required this.isEnabled,
    required this.initialThresholdMinutes,
    required this.repeatIntervalMinutes,
    this.snoozedUntil,
  });

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'isEnabled': isEnabled,
      'initialThresholdMinutes': initialThresholdMinutes,
      'repeatIntervalMinutes': repeatIntervalMinutes,
      'snoozedUntil': snoozedUntil,
    };
  }

  factory AppRuleModel.fromJson(Map<String, dynamic> json) {
    return AppRuleModel(
      packageName: json['packageName'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
      initialThresholdMinutes: json['initialThresholdMinutes'] as int? ?? 30,
      repeatIntervalMinutes: json['repeatIntervalMinutes'] as int? ?? 10,
      snoozedUntil: json['snoozedUntil'] as String?,
    );
  }
}