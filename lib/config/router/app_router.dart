import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tempo/presentation/screens/index.dart'; 
import 'package:tempo/presentation/widgets/shared/custom_bottom_navigation.dart'; 

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRoute = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        // Envolvemos la pantalla actual con el menú inferior
        return Scaffold(
          body: navigationShell,
          bottomNavigationBar: CustomBottomNavigation(
            navigationShell: navigationShell,
          ),
        );
      },
      branches: [
        // Rama 1: Home Screen (Uso Hoy)[cite: 2]
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              name: HomeScreen.name,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        
        // Rama 2: Apps Config Screen (Todas las Apps)[cite: 2]
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/apps-config',
              name: AppsConfigScreen.name,
              builder: (context, state) => const AppsConfigScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);