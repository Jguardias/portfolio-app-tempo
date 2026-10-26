import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/config/theme/app_theme.dart';
import 'package:tempo/presentation/providers/appUsage/app_search_provider.dart';
import 'package:tempo/presentation/providers/appUsage/app_usage_provider_datasource.dart';
import 'package:tempo/presentation/widgets/home/app_usage_tile.dart';
import 'package:tempo/presentation/widgets/shared/app_search_bar.dart';
import 'package:tempo/presentation/widgets/shared/section_header.dart';
import 'package:tempo/presentation/widgets/home/summary_entry_card.dart';


class HomeScreen extends ConsumerStatefulWidget {
  static const name = "home-screen";
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  // Evita recalcular todo el uso (y cargar iconos) cada vez que la app vuelve a primer plano
  static const int _minSecondsBetweenRefresh = 30;
  DateTime _lastRefresh = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      if (now.difference(_lastRefresh).inSeconds >= _minSecondsBetweenRefresh) {
        _lastRefresh = now;
        ref.invalidate(appUsageProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appsAsync = ref.watch(appUsageProvider);
    final query = ref.watch(appSearchQueryHomeProvider).toLowerCase().trim();

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
                  ref.read(appSearchQueryHomeProvider.notifier).state = value;
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
            const SectionHeader(
              title: "Tu Equilibrio Digital.",
              subtitle:
                  "Toma conciencia de cómo usas tu tiempo y encuentra el balance perfecto para tu día a día.",
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
                      child: Text("No se encontraron aplicaciones."),
                    ),
                  );
                }

                // Total y máximo del día (las barras se comparan con la app más usada)
                int totalMs = 0;
                int maxMs = 0;
                for (final app in apps) {
                  final ms = app.totalTimeInForeground.inMilliseconds;
                  totalMs += ms;
                  if (ms > maxMs) maxMs = ms;
                }
                final maxUsage = Duration(milliseconds: maxMs);

                return SliverMainAxisGroup(
                  slivers: [
                    if (query.isEmpty) ...[
                      const SliverToBoxAdapter(child: SummaryEntryCard()),
                      SliverToBoxAdapter(
                        child: _TotalSummary(
                          total: Duration(milliseconds: totalMs),
                        ),
                      ),
                    ],
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        childCount: filteredApps.length,
                        (context, index) => AppUsageTile(
                          app: filteredApps[index],
                          maxUsage: maxUsage,
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => SliverToBoxAdapter(
                child: Center(child: Text("Error: $error")),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }
}

class _TotalSummary extends StatelessWidget {
  final Duration total;

  const _TotalSummary({required this.total});

  String _format(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (hours > 0) return "$hours h $minutes min";
    return "${d.inMinutes} min";
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.getTileColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.getBorderColor(context)),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule_rounded, color: primary),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Total hoy en tus apps",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              _format(total),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}