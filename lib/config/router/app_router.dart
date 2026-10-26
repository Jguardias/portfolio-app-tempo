import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usage_stats/usage_stats.dart';
import 'package:tempo/presentation/screens/index.dart';
import 'package:tempo/presentation/widgets/shared/custom_bottom_navigation.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRoute = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstOpen = prefs.getBool('is_first_open') ?? true;

    // Verificación en tiempo real del estado de los permisos
    final bool hasUsagePermission = await UsageStats.checkUsagePermission() ?? false;
    final bool hasOverlayPermission = await Permission.systemAlertWindow.isGranted;

    final bool isMissingPermissions = !hasUsagePermission || !hasOverlayPermission;

    // Si es la primera apertura O falta algún permiso, redirige al Tutorial
    if ((isFirstOpen || isMissingPermissions) && state.matchedLocation != '/tutorial') {
      return '/tutorial';
    }

    // Si ya completó el tutorial Y tiene ambos permisos, pero intenta ir a /tutorial, lo manda a Home
    if (!isFirstOpen && !isMissingPermissions && state.matchedLocation == '/tutorial') {
      return '/';
    }

    return null;
  },
  routes: [
    // Ruta independiente para el Tutorial (sin BottomNavigationBar)
    GoRoute(
      path: '/tutorial',
      name: AppTutorialScreen.name,
      builder: (context, state) => const AppTutorialScreen(),
    ),
    
    GoRoute(
      path: '/summary',
      name: SummaryScreen.name,
      builder: (context, state) => const SummaryScreen(),
    ),
    
    // Rutas con BottomNavigationBar persistente
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: CustomBottomNavigation(
            navigationShell: navigationShell,
          ),
        );
      },
      branches: [
        // Rama 1: Home Screen (Uso Hoy)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              name: HomeScreen.name,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),

        // Rama 2: Apps Config Screen (Todas las Apps)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/apps-config',
              name: AppsConfigScreen.name,
              builder: (context, state) => const AppsConfigScreen(),
            ),
          ],
        ),

        // Rama 3: Ajustes
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              name: SettingsScreen.name,
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);