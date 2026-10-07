import 'package:tempo/domain/entities/app_info_device.dart';
import 'package:tempo/infrastructure/mappers/helpers/category_translator.dart';
import 'package:tempo/infrastructure/models/app_metadata_model.dart';

class AppInfoMapper {
 
  static AppInfoDevice toEntity(AppMetaData model) {
    return AppInfoDevice(
      packageName: model.packageName,
       appName: model.appName,
        icon: model.icon,
        isSystemApp: model.isSystemApp,
        category: CategoryTranslator.mapCategory(model.category),
    );
  }
}