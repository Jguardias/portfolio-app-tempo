import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/config/theme/app_theme.dart';
import 'package:tempo/presentation/providers/appUsage/app_usage_provider_datasource.dart';
import 'package:tempo/presentation/widgets/apps_config/app_config_tile.dart';
import 'package:tempo/presentation/widgets/shared/section_header.dart';

class AppsConfigScreen extends ConsumerWidget {
  static const name = 'apps-config-screen';

  const AppsConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(allAppsProvider);

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            SliverAppBar(
              backgroundColor: AppTheme.getBackgroundColor(context),
              title: const Padding(
                padding: EdgeInsets.all(10.0),
                child: SearchBar(
                  hintText: "Buscar aplicación en Tempo",
                  elevation: WidgetStatePropertyAll(0),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      side: BorderSide.none,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 10)),

            const SectionHeader(
              title: "Configuración de Interrupciones.",
              subtitle:
                  "Define el tiempo límite inicial y la frecuencia con la que Tempo te invitará a pausar tu uso.",
            ),

            appsAsync.when(
              data: (apps) {
                if (apps.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Text("No se encontraron aplicaciones instaladas."),
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return AppConfigTile(app: apps[index]);
                    },
                    childCount: apps.length,
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => SliverToBoxAdapter(
                child: Center(child: Text("Error al cargar aplicaciones: $error")),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}