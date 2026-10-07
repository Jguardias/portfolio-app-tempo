import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/config/router/app_router.dart';
import 'package:tempo/config/theme/app_theme.dart';
import 'package:tempo/presentation/overlays/overlay_view.dart';
import 'package:tempo/infrastructure/services/tempo_background_service.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await initializeBackgroundService();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: "Tempo",
      debugShowCheckedModeBanner: false,
      routerConfig: appRoute,
      theme: AppTheme().getTheme(Brightness.light),
    );
  }
}

@pragma("vm:entry-point")
void overlayMain() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const TempoOverlayScreen(),
    ),
  );
}