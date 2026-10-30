import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/config/router/app_router.dart';
import 'package:tempo/config/theme/app_theme.dart';
import 'package:tempo/infrastructure/services/tempo_background_service.dart';
import 'package:tempo/presentation/providers/settings/theme_mode_provider.dart';
import 'package:tempo/presentation/screens/splash/tempo_splash.dart';
import 'package:tempo/presentation/providers/settings/purchase_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Primero se dibuja la app; el servicio arranca después para no retrasar el primer cuadro.
  runApp(const ProviderScope(child: MyApp()));

  initializeBackgroundService().catchError((Object e) {
    debugPrint("[Main] No se pudo iniciar el servicio: $e");
  });
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    // Arranca la escucha de compras desde el inicio de la app
    ref.read(purchaseProvider);
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final lightTheme = AppTheme().getTheme(Brightness.light);
    final darkTheme = AppTheme().getTheme(Brightness.dark);

    if (_showSplash) {
      return MaterialApp(
        title: "Tempo",
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        home: TempoSplash(
          onFinished: () => setState(() => _showSplash = false),
        ),
      );
    }

    return MaterialApp.router(
      title: "Tempo",
      debugShowCheckedModeBanner: false,
      routerConfig: appRoute,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
    );
  }
}