class AppRuleModel {
  final String packageName;
  final bool isEnabled;
  final int initialThresholdMinutes;
  final int repeatIntervalMinutes;
  final DateTime? snoozedUntil;

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
      'snoozedUntil': snoozedUntil?.toIso8601String(),
    };
  }

  factory AppRuleModel.fromJson(Map<String, dynamic> json) {
    return AppRuleModel(
      packageName: json['packageName'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
      initialThresholdMinutes: json['initialThresholdMinutes'] as int? ?? 30,
      repeatIntervalMinutes: json['repeatIntervalMinutes'] as int? ?? 10,
      snoozedUntil: json['snoozedUntil'] != null 
          ? DateTime.parse(json['snoozedUntil'] as String) 
          : null,
    );
  }
}