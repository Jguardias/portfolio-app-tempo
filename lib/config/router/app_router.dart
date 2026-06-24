import 'package:go_router/go_router.dart';
import 'package:tempo/presentation/screens/index.dart';

final GoRouter appRoute = GoRouter(
  initialLocation: "/",
  routes: <GoRoute>[
    GoRoute(
      path: "/",
      name: HomeScreen.name,
      builder: (context, state) => HomeScreen(),
      )
  ]
  
  );
