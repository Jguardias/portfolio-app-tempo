import 'dart:async';
import 'dart:ui';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:tempo/config/constants/excluded_apps.dart';
import 'package:tempo/config/helpers/tempo_log.dart';
import 'package:tempo/config/theme/overlay_gradients.dart';
import 'package:tempo/domain/datasources/app_rules_datasource.dart';
import 'package:tempo/domain/datasources/app_usage_datasource.dart';
import 'package:tempo/infrastructure/datasources/app_info_datasource_impl.dart';
import 'package:tempo/infrastructure/datasources/app_rules_local_datasource_impl.dart';
import 'package:tempo/infrastructure/datasources/app_usage_datasource_impl.dart';
import 'package:tempo/infrastructure/services/pause_event_store.dart';
import 'package:tempo/infrastructure/services/quote_service.dart';

/// Segundos que el usuario debe esperar antes de poder continuar.
const int _pauseCountdownSeconds = 5;

/// La ventana nativa se oculta sola a los 60 s.
const int _pauseMaxSeconds = 60;

String _hex(Color c) =>
    '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

/// Ordena a la ventana nativa (PauseOverlay.kt) que muestre la pausa.
Future<void> _showPause({
  required String appName,
  required String quote,
  required String footer,
  required bool askIntent,
  required String pauseId,
  required String question,
  required String intentPrompt,
}) async {
  final colors = OverlayGradients.getRandom().colors;
  await AndroidIntent(
    action: '${ExcludedApps.ownPackage}.SHOW_PAUSE',
    package: ExcludedApps.ownPackage,
    arguments: <String, dynamic>{
      'appName': appName,
      'quote': quote,
      'footer': footer,
      'askIntent': askIntent,
      'pauseId': pauseId,
      'question': question,
      'intentPrompt': intentPrompt,
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

  final Map<String, String> nameCache = {};
  final Map<String, String> categoryCache = {};

  // Estado de la pausa visible (pausedPackage == null significa que no hay pausa)
  String? pausedPackage;
  String? pausedId;
  String pausedMode = 'time';
  DateTime? pausedAt;

  // Última app vista en primer plano: sirve para detectar "acaba de abrirse"
  String? lastSeen;

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

  Future<String> resolveName(String pkg) async {
    final cached = nameCache[pkg];
    if (cached != null) return cached;
    try {
      final name = await infoDatasource.getAppName(pkg);
      if (name != null && name.isNotEmpty) {
        nameCache[pkg] = name;
        return name;
      }
    } catch (e) {
      tempoLog("[Tempo Service] No se pudo obtener el nombre de $pkg: $e");
    }
    return pkg;
  }

  Future<String?> resolveCategory(String pkg) async {
    final cached = categoryCache[pkg];
    if (cached != null) return cached;
    try {
      final category = await infoDatasource.getAppCategory(pkg);
      if (category != null) {
        categoryCache[pkg] = category;
        return category;
      }
    } catch (e) {
      tempoLog("[Tempo Service] No se pudo obtener la categoría de $pkg: $e");
    }
    return null;
  }

  /// Registra el evento de la pausa que acaba de terminar.
  Future<void> finalizePause(String action, String? intent) async {
    final pkg = pausedPackage;
    if (pkg != null) {
      try {
        await PauseEventStore.append(PauseEvent(
          time: DateTime.now().millisecondsSinceEpoch,
          packageName: pkg,
          mode: pausedMode,
          intent: intent,
          action: action,
        ));
      } catch (e) {
        tempoLog("[Tempo Service] No se pudo guardar el evento: $e");
      }
      tempoLog("[Tempo Service] Pausa cerrada ($action, motivo: ${intent ?? '-'}) en $pkg.");
    }
    pausedPackage = null;
    pausedId = null;
    pausedAt = null;
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

      // ¿Acaba de abrirse esta app? (cambió respecto al ciclo anterior)
      final bool justOpened = current != lastSeen;
      lastSeen = current;

      // 1. HAY UNA PAUSA VISIBLE
      if (pausedPackage != null) {
        final slot = await PauseEventStore.readSlot();
        final bool slotMatches =
            slot != null && slot['id']?.toString() == pausedId;
        final String? slotAction =
            slotMatches ? slot['action'] as String? : null;
        final String? slotIntent =
            slotMatches ? slot['intent'] as String? : null;
        final int elapsed = DateTime.now().difference(pausedAt!).inSeconds;

        if (slotAction != null) {
          // La ventana nativa ya terminó (Continuar, Salir o tiempo agotado)
          await finalizePause(slotAction, slotIntent);
          return;
        }

        final bool transient = current == null ||
            current == ExcludedApps.ownPackage ||
            current.contains('systemui') ||
            current.contains('inputmethod');

        if (elapsed >= _pauseMaxSeconds + 5) {
          await _hidePause();
          await finalizePause('timeout', slotIntent);
          return;
        }

        if (!transient && current != pausedPackage) {
          tempoLog("[Tempo Service] El usuario salió de $pausedPackage hacia $current.");
          await _hidePause();
          await finalizePause('left', slotIntent);
        }
        return;
      }

      // 2. APP EN PRIMER PLANO VÁLIDA
      if (current == null || ExcludedApps.isExcluded(current)) return;

      // 3. REGLA
      final rule = await rulesDatasource.getRuleForPackage(current);
      if (rule == null || !rule.isEnabled) return;

      // En modo "al abrir" solo se evalúa en el momento de abrir la app
      if (rule.triggerOnOpen && !justOpened) return;

      // 4. PAUSA ENTRE AVISOS (snooze)
      final now = DateTime.now();
      if (rule.snoozedUntil != null && now.isBefore(rule.snoozedUntil!)) {
        if (!rule.triggerOnOpen) {
          final remaining = rule.snoozedUntil!.difference(now).inSeconds;
          tempoLog("[Tempo Service] $current en pausa. Faltan ${remaining}s.");
        }
        return;
      }

      // 5. ¿SE CUMPLE LA REGLA?
      bool shouldShow = rule.triggerOnOpen;
      if (!rule.triggerOnOpen) {
        final usage = await usageDatasource.getDailyUsageForPackage(current);
        shouldShow = usage.inMinutes >= rule.initialThresholdMinutes;
      }
      if (!shouldShow) return;

      tempoLog("[Tempo Service] Regla cumplida para $current (${rule.triggerOnOpen ? 'al abrir' : 'por tiempo'}). Mostrando pausa...");

      final appName = await resolveName(current);
      final category = await resolveCategory(current);
      final quote = QuoteService().getRandomQuote(category: category);
      final askIntent = await PauseEventStore.shouldAskIntent(current);
      final pauseId = DateTime.now().millisecondsSinceEpoch.toString();

      final n = rule.repeatIntervalMinutes;
      final question = rule.triggerOnOpen
          ? "¿Qué vas a hacer en $appName?"
          : "¿Sigue siendo tu intención estar en $appName?";
      final intentPrompt = rule.triggerOnOpen
          ? "¿Para qué la vas a usar? (opcional)"
          : "¿Para qué la sigues usando? (opcional)";
      final footer = rule.triggerOnOpen
          ? "Si vuelves a abrir esta app en menos de $n minutos, no te mostraremos otra pausa."
          : "Si sigues usándola, te mostraremos otra pausa en $n minutos.";

      // La pausa entre avisos empieza ahora, así que nunca se repite en bucle
      await rulesDatasource.saveSnooze(
        current,
        now.add(Duration(minutes: rule.repeatIntervalMinutes)),
      );

      try {
        await _showPause(
          appName: appName,
          quote: quote,
          footer: footer,
          askIntent: askIntent,
          pauseId: pauseId,
          question: question,
          intentPrompt: intentPrompt,
          
        );
        pausedPackage = current;
        pausedId = pauseId;
        pausedMode = rule.triggerOnOpen ? 'open' : 'time';
        pausedAt = DateTime.now();
      } catch (e) {
        tempoLog("[Tempo Service] No se pudo enviar la pausa: $e");
      }
    } catch (e) {
      tempoLog("[Tempo Service] Error en ciclo de monitoreo: $e");
    } finally {
      isProcessingCycle = false;
    }
  });
}