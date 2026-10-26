import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/infrastructure/datasources/app_info_datasource_impl.dart';
import 'package:tempo/infrastructure/services/pause_event_store.dart';

/// Se vuelve a leer cada vez que se abre la pantalla.
final pauseEventsProvider = FutureProvider.autoDispose<List<PauseEvent>>((ref) {
  return PauseEventStore.readAll();
});

/// Nombre legible de una app (sin cargar iconos).
final appNameProvider =
    FutureProvider.autoDispose.family<String, String>((ref, packageName) async {
  try {
    return await AppInfoDatasourceImpl().getAppName(packageName) ?? packageName;
  } catch (_) {
    return packageName;
  }
});