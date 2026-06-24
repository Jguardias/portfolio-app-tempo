import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/presentation/providers/appUsage/app_usage_provider_datasource.dart';

class HomeScreen extends ConsumerStatefulWidget {
  static const name = "home-screen";

  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final appsUsageAsync = ref.watch(appUsageProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Uso de Aplicaciones"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(appUsageProvider),
          )
        ],
      ),
      body: appsUsageAsync.when(
        data: (apps) {
          if (apps.isEmpty) {
            return const Center(child: Text("No hay datos disponibles."));
          }
          return ListView.builder(
            itemCount: apps.length,
            itemBuilder: (context, index) {
              final app = apps[index];
              return ListTile(
                title: Text(app.appName),
                subtitle: Text("Uso: ${app.totalTimeInForeground.inMinutes} min"),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text("Error: $error")),
      ),
    );
  }
}