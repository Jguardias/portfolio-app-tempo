import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/config/router/app_router.dart';
import 'package:tempo/config/theme/app_theme.dart';
void main() async{
  
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
      theme: AppTheme().getTheme(),
    );
  }
}

