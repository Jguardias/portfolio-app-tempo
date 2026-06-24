import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/domain/entities/app_usage.dart';
import 'package:tempo/presentation/providers/appUsage/app_usage_provider_repository.dart';

final appUsageProvider = FutureProvider<List<AppUsage>>((ref) async {
  final repository = ref.watch(appUsageRepositoryProvider);
  return await repository.getDailyUsageStats();
});