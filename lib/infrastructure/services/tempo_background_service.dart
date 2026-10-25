import 'dart:async';
import 'dart:ui';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tempo/config/constants/excluded_apps.dart';
import 'package:tempo/config/theme/overlay_gradients.dart';
import 'package:tempo/domain/datasources/app_rules_datasource.dart';
import 'package:tempo/domain/datasources/app_usage_datasource.dart';
import 'package:tempo/infrastructure/datasources/app_info_datasource_impl.dart';
import 'package:tempo/infrastructure/datasources/app_rules_local_datasource_impl.dart';
import 'package:tempo/infrastructure/datasources/app_usage_datasource_impl.dart';
import 'package:tempo/infrastructure/services/quote_service.dart';
import 'package:tempo/config/helpers/tempo_log.dart';

/// Segundos que el usuario debe esperar antes de poder continuar.
const int _pauseCountdownSeconds = 5;

/// La ventana nativa se oculta sola a los 60 s; el servicio lo asume igual.
const int _pauseMaxSeconds = 60;

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// Ordena a la ventana nativa (PauseOverlay.kt) que muestre la pausa.
Future<void> _showPause({
  required String appName,
  required int repeatMinutes,
}) async {
  final colors = OverlayGradients.getRandom().colors;
  await AndroidIntent(
    action: '${ExcludedApps.ownPackage}.SHOW_PAUSE',
    package: ExcludedApps.ownPackage,
    arguments: <String, dynamic>{
      'appName': appName,
      'quote': QuoteService().getRandomQuote(),
      'repeatMinutes': repeatMinutes,
      'countdownSeconds': _pauseCountdownSeconds,
      'c1': _hex(colors[0]),
      'c2': _hex(colors[1]),
      'c3': _hex(colors[2]),
    },
  ).sendBroadcast();
}

Future<void> _hidePause() async {
  await AndroidIntent(
    action: '${ExcludedApps.ownPackage}.HIDE_PAUSE',
    package: ExcludedApps.ownPackage,
  ).sendBroadcast();
}

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
      initialNotificationTitle: 'Tempo Activo',
      initialNotificationContent: 'Monitoreando tu tiempo digital...',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
    ),
  );
}

/// Reinicia el servicio para que la notificación vuelva a publicarse
/// (útil cuando el permiso de notificaciones se concede después de arrancar).
Future<void> restartBackgroundService() async {
  final service = FlutterBackgroundService();

  if (await service.isRunning()) {
    service.invoke('stopService');
    await Future.delayed(const Duration(milliseconds: 800));
  }

  await service.startService();
}

@pragma('vm:entry-point')
void onStartService(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  if (service is AndroidServiceInstance) {
    service.setAsForegroundService();
    service.setForegroundNotificationInfo(
      title: "Tempo Activo",
      content: "Monitoreando tu tiempo digital...",
    );
  }

  final AppUsageDatasources usageDatasource = AppUsageDatasourceImpl();
  final AppRulesDatasource rulesDatasource = AppRulesLocalDatasourceImpl();
  final AppInfoDatasource infoDatasource = AppInfoDatasourceImpl();

  final Map<String, String> appNameCache = {};

  // App sobre la que hay una pausa visible (null = no hay pausa)
  String? pausedPackage;
  DateTime? pausedAt;

  bool isProcessingCycle = false;
  Timer? monitorTimer;

  service.on('stopService').listen((event) {
    monitorTimer?.cancel();
    service.stopSelf();
  });

  tempoLog("[Tempo Service] Servicio en segundo plano iniciado correctamente.");

  // Por si quedó una pausa de una sesión anterior
  try {
    await _hidePause();
  } catch (_) {}

  Future<String> resolveAppName(String packageName) async {
    final cached = appNameCache[packageName];
    if (cached != null) return cached;
    try {
      final name = await infoDatasource.getAppName(packageName);
      if (name != null && name.isNotEmpty) {
        appNameCache[packageName] = name;
        return name;
      }
    } catch (e) {
      tempoLog("[Tempo Service] No se pudo obtener el nombre de $packageName: $e");
    }
    return packageName;
  }

  monitorTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
    if (service is AndroidServiceInstance) {
      if (!(await service.isForegroundService())) return;
    }

    if (isProcessingCycle) return;
    isProcessingCycle = true;

    try {
      final String? current =
          await usageDatasource.getForegroundAppPackageName();

      // 1. HAY UNA PAUSA VISIBLE: solo se vigila si el usuario salió de la app
      if (pausedPackage != null) {
        final elapsed = DateTime.now().difference(pausedAt!).inSeconds;
        final bool transient = current == null ||
            current == ExcludedApps.ownPackage ||
            current.contains('systemui') ||
            current.contains('inputmethod');

        if (elapsed >= _pauseMaxSeconds) {
          pausedPackage = null;
        } else if (!transient && current != pausedPackage) {
          tempoLog("[Tempo Service] El usuario salió de $pausedPackage hacia $current. Ocultando pausa.");
          await _hidePause();
          pausedPackage = null;
        }
        return;
      }

      // 2. APP EN PRIMER PLANO VÁLIDA
      if (current == null || ExcludedApps.isExcluded(current)) return;

      // 3. REGLA Y PAUSA (SNOOZE)
      final rule = await rulesDatasource.getRuleForPackage(current);
      if (rule == null || !rule.isEnabled) return;

      final now = DateTime.now();
      if (rule.snoozedUntil != null && now.isBefore(rule.snoozedUntil!)) {
        final remaining = rule.snoozedUntil!.difference(now).inSeconds;
        tempoLog("[Tempo Service] $current en pausa. Faltan ${remaining}s.");
        return;
      }

      // 4. USO DE HOY DE ESTA APP
      final usage = await usageDatasource.getDailyUsageForPackage(current);
      final minutes = usage.inMinutes;

      // 5. UMBRAL
      if (minutes >= rule.initialThresholdMinutes) {
        tempoLog("[Tempo Service] Límite alcanzado para $current ($minutes min). Mostrando pausa...");
        final appName = await resolveAppName(current);

        // La pausa (snooze) empieza ahora, así que nunca se repite en bucle
        await rulesDatasource.saveSnooze(
          current,
          now.add(Duration(minutes: rule.repeatIntervalMinutes)),
        );

        try {
          await _showPause(
            appName: appName,
            repeatMinutes: rule.repeatIntervalMinutes,
          );
          pausedPackage = current;
          pausedAt = DateTime.now();
        } catch (e) {
          tempoLog("[Tempo Service Error] No se pudo enviar la pausa: $e");
        }
      }
    } catch (e) {
      tempoLog("[Tempo Service Error] Error en ciclo de monitoreo: $e");
    } finally {
      isProcessingCycle = false;
    }
  });
}