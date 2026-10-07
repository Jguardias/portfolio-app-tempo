import 'dart:async';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart' as overlay_win;
import 'package:tempo/domain/datasources/app_rules_datasource.dart';
import 'package:tempo/domain/entities/app_usage.dart';
import 'package:tempo/infrastructure/datasources/app_rules_local_datasource_impl.dart';
import 'package:tempo/infrastructure/datasources/app_usage_datasource_impl.dart';

Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'tempo_foreground_channel',
    'Tempo Servicio Activo',
    description: 'Canal de servicio para mantener activo el monitoreo.',
    importance: Importance.low,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStartService,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: 'tempo_foreground_channel',
      initialNotificationTitle: 'Tempo',
      initialNotificationContent: 'Servicio en ejecución',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
    ),
  );
}

@pragma('vm:entry-point')
void onStartService(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final usageDatasource = AppUsageDatasourceImpl();
  final AppRulesDatasource rulesDatasource = AppRulesLocalDatasourceImpl();

  // Reemplaza esto con el applicationId/packageName de tu app en android/app/build.gradle si es diferente
  const String myPackageName = 'com.example.tempo';

  // Guarda el nombre del paquete que provocó el despliegue del Overlay
  String? activeOverlayPackage;

  print("🚀 [Tempo Service] Servicio en segundo plano iniciado correctamente.");

  Timer.periodic(const Duration(seconds: 2), (timer) async {
    if (service is AndroidServiceInstance) {
      if (!(await service.isForegroundService())) return;
    }

    try {
      final String? currentPackage = await usageDatasource.getForegroundAppPackageName();
      final bool isOverlayActive = await overlay_win.FlutterOverlayWindow.isActive();

      // 1. SI EL OVERLAY YA ESTÁ VISIBLE EN PANTALLA:
      if (isOverlayActive) {
        final bool isDifferentApp = currentPackage != null &&
            currentPackage != activeOverlayPackage &&
            currentPackage != myPackageName &&
            !currentPackage.contains('launcher') &&
            !currentPackage.contains('home');

        if (isDifferentApp) {
          print("🚪 [Tempo Service] Cambio de app detectado ($currentPackage != $activeOverlayPackage). Cerrando Overlay.");
          await overlay_win.FlutterOverlayWindow.closeOverlay();
          activeOverlayPackage = null;
        }
        return;
      }

      // 2. SI EL OVERLAY NO ESTÁ ACTIVO:
      if (currentPackage == null || currentPackage == myPackageName) {
        return;
      }

      // 3. Leer regla guardada para la app en pantalla
      final rule = await rulesDatasource.getRuleForPackage(currentPackage);

      if (rule == null) {
        // Descomenta si deseas ver las apps que no tienen reglas configuradas:
        // print("ℹ️ [Tempo Service] Sin regla configurada para: $currentPackage");
        return;
      }

      if (!rule.isEnabled) {
        print("⏸️ [Tempo Service] Regla deshabilitada para $currentPackage");
        return;
      }

      print("📋 [Tempo Service] Regla leída de $currentPackage -> Umbral: ${rule.initialThresholdMinutes}m | Repetir: ${rule.repeatIntervalMinutes}m | Snooze: ${rule.snoozedUntil}");

      // 4. Validar si está en periodo de pausa (Snooze)
      final now = DateTime.now();
      if (rule.snoozedUntil != null && now.isBefore(rule.snoozedUntil!)) {
        final remainingSecs = rule.snoozedUntil!.difference(now).inSeconds;
        print("⏳ [Tempo Service] $currentPackage está en pausa (Snooze). Faltan ${remainingSecs}s para reevaluar.");
        return;
      }

      // 5. Obtener uso diario acumulado
      final dailyStats = await usageDatasource.getDailyUsageStats();
      final appUsage = dailyStats.firstWhere(
        (app) => app.packageName == currentPackage,
        orElse: () => AppUsage(
          packageName: currentPackage,
          totalTimeInForeground: Duration.zero,
          lastTimeUsed: DateTime.now(),
        ),
      );

      final dailyUsageMinutes = appUsage.totalTimeInForeground.inMinutes;

      print("📊 [Tempo Service] $currentPackage -> Uso acumulado hoy: ${dailyUsageMinutes}m / Limite: ${rule.initialThresholdMinutes}m");

      // 6. Evaluar si superó el límite inicial
      if (dailyUsageMinutes >= rule.initialThresholdMinutes) {
        print("🚨 [Tempo Service] Límite alcanzado/superado para $currentPackage. Mostrando Overlay...");
        activeOverlayPackage = currentPackage;

        await overlay_win.FlutterOverlayWindow.showOverlay(
          height: overlay_win.WindowSize.fullCover,
          width: overlay_win.WindowSize.matchParent,
          alignment: overlay_win.OverlayAlignment.center,
          flag: overlay_win.OverlayFlag.focusPointer,
          visibility: overlay_win.NotificationVisibility.visibilityPublic,
        );

        for (int i = 0; i < 3; i++) {
          await Future.delayed(const Duration(milliseconds: 250));
          await overlay_win.FlutterOverlayWindow.shareData({
            'packageName': currentPackage,
            'appName': appUsage.appName ?? currentPackage,
            'dailyUsageMinutes': dailyUsageMinutes,
            'initialThresholdMinutes': rule.initialThresholdMinutes,
            'repeatIntervalMinutes': rule.repeatIntervalMinutes,
          });
        }
      }
    } catch (e) {
      print("❌ [Tempo Service Error] Error en ciclo de monitoreo: $e");
    }
  });
}