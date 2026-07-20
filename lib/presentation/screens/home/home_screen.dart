import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/config/theme/app_theme.dart';
import 'package:tempo/presentation/providers/appUsage/app_usage_provider_datasource.dart';
import 'package:tempo/presentation/widgets/home/home_header.dart';
import 'package:tempo/presentation/widgets/home/app_usage_tile.dart';

class HomeScreen extends ConsumerStatefulWidget {
  static const name = "home-screen";
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final apps = ref.watch(appUsageProvider);

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
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                    side: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  )),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 10)),
            const HomeHeader(),
            apps.when(
              data: (apps) {
                if (apps.isEmpty) {
                  return const SliverFillRemaining(child: Center(child: Text("No hay datos disponibles.")));
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    childCount: apps.length,
                    (context, index) => AppUsageTile(app: apps[index]),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (error, stack) => SliverToBoxAdapter(child: Center(child: Text("Error: $error"))),
            ),
          ],
        ),
      ),
    );
  }
}