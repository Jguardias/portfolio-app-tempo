import 'package:tempo/domain/entities/app_rule.dart';
import 'package:tempo/infrastructure/models/app_rule_model.dart';

class AppRuleMapper {
  static AppRule toEntity(AppRuleModel model) {
    return AppRule(
      packageName: model.packageName,
      isEnabled: model.isEnabled,
      initialThresholdMinutes: model.initialThresholdMinutes,
      repeatIntervalMinutes: model.repeatIntervalMinutes,
      triggerOnOpen: model.triggerOnOpen,
      snoozedUntil: model.snoozedUntil,
    );
  }

  static AppRuleModel toModel(AppRule entity) {
    return AppRuleModel(
      packageName: entity.packageName,
      isEnabled: entity.isEnabled,
      initialThresholdMinutes: entity.initialThresholdMinutes,
      repeatIntervalMinutes: entity.repeatIntervalMinutes,
      triggerOnOpen: entity.triggerOnOpen,
      snoozedUntil: entity.snoozedUntil,
    );
  }
}