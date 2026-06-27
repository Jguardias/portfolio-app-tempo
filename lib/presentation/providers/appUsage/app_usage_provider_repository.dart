import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/domain/repositories/app_usage_repository.dart';
import 'package:tempo/infrastructure/datasources/app_usage_datasource_impl.dart';
import 'package:tempo/infrastructure/repositories/app_usage_repository_impl.dart';

final appUsageRepositoryProvider = Provider<AppUsageRepositories>((ref){
  return AppUsageRepositoryImpl(AppUsageDatasourceImpl(), AppIconDatasourceImpl());
});