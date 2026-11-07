import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/config/theme/app_theme.dart';
import 'package:tempo/domain/entities/app_usage.dart';
import 'package:tempo/presentation/providers/appRules/app_rules_provider.dart';
import 'package:tempo/presentation/providers/appUsage/app_search_provider.dart';
import 'package:tempo/presentation/providers/appUsage/app_usage_provider_datasource.dart';
import 'package:tempo/presentation/widgets/apps_config/app_config_tile.dart';
import 'package:tempo/presentation/widgets/shared/app_search_bar.dart';
import 'package:tempo/presentation/widgets/shared/section_header.dart';

class AppsConfigScreen extends ConsumerWidget {
  static const name = 'apps-config-screen';

  const AppsConfigScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appsAsync = ref.watch(allAppsProvider);
    final query = ref.watch(appSearchQueryConfigProvider).toLowerCase().trim();
    final rules = ref.watch(appRulesProvider);

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverAppBar(
              backgroundColor: AppTheme.getBackgroundColor(context),
              title: AppSearchBar(
                hintText: "Buscar aplicación en Tempo",
                onChanged: (value) {
                  ref.read(appSearchQueryConfigProvider.notifier).state = value;
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
            const SectionHeader(
              title: "Configuración de Interrupciones.",
              subtitle:
                  "Activa el interruptor para monitorear una app y toca la tarjeta para ajustar los tiempos.",
            ),
            appsAsync.when(
              data: (apps) {
                final filteredApps = apps.where((app) {
                  final nameMatches =
                      (app.appName ?? '').toLowerCase().contains(query);
                  final packageMatches =
                      app.packageName.toLowerCase().contains(query);
                  return nameMatches || packageMatches;
                }).toList();

                if (filteredApps.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Text("No se encontraron aplicaciones instaladas."),
                    ),
                  );
                }

                bool isActive(AppUsage app) =>
                    rules[app.packageName]?.isEnabled ?? false;

                final active = filteredApps.where(isActive).toList();
                final others =
                    filteredApps.where((app) => !isActive(app)).toList();

                // Aviso para quien aún no activó ninguna app
                final bool noneActiveAtAll =
                    !apps.any(isActive) && query.isEmpty;

                return SliverMainAxisGroup(
                  slivers: [
                    if (noneActiveAtAll)
                      const SliverToBoxAdapter(child: _FirstAppHint()),
                    if (active.isNotEmpty) ...[
                      _ListLabel(
                        icon: Icons.notifications_active_rounded,
                        text: "Monitoreadas (${active.length})",
                      ),
                      _AppsSliver(apps: active),
                    ],
                    if (others.isNotEmpty) ...[
                      if (active.isNotEmpty)
                        const _ListLabel(
                          icon: Icons.apps_rounded,
                          text: "Otras aplicaciones",
                        ),
                      _AppsSliver(apps: others),
                    ],
                  ],
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

class _FirstAppHint extends StatelessWidget {
  const _FirstAppHint();

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primary.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.toggle_on_rounded, color: primary, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activa tu primera app',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Usa el interruptor de una app de la lista y Tempo te mostrará una pausa cuando la uses. Toca la tarjeta para elegir cuándo.',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AppsSliver extends StatelessWidget {
  final List<AppUsage> apps;

  const _AppsSliver({required this.apps});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => AppConfigTile(
          key: ValueKey(apps[index].packageName),
          app: apps[index],
        ),
        childCount: apps.length,
      ),
    );
  }
}

class _ListLabel extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ListLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSegundary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}