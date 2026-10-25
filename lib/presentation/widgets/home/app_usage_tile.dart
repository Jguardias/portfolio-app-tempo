import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tempo/config/theme/app_theme.dart';
import 'package:tempo/domain/entities/app_usage.dart';
import 'package:tempo/domain/entities/app_usage_extensions.dart';
import 'package:tempo/presentation/widgets/home/app_info_widgets.dart';

class AppUsageTile extends StatelessWidget {
  final AppUsage app;

  /// Uso de la app más usada hoy: la barra se dibuja en proporción a este valor.
  final Duration maxUsage;

  const AppUsageTile({
    super.key,
    required this.app,
    this.maxUsage = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    // Si no hay dato real, la fecha cae en 1970: en ese caso no se muestra
    final firstUsed = app.firstUsed;
    final hasFirstUsed = firstUsed != null && firstUsed.year > 2000;

    final double ratio = maxUsage.inMilliseconds <= 0
        ? 0
        : (app.totalTimeInForeground.inMilliseconds / maxUsage.inMilliseconds)
            .clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ExpansionTile(
        backgroundColor: AppTheme.getTileColor(context),
        collapsedBackgroundColor: AppTheme.getTileColor(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.getBorderColor(context)),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppTheme.getBorderColor(context)),
        ),
        leading: app.icon != null
            ? Image.memory(app.icon!, width: 40, height: 40)
            : const Icon(Icons.apps, size: 40),
        title: Text(
          app.appName ?? "App sin nombre",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(app.formattedDuration),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: ratio,
              minHeight: 4,
              borderRadius: BorderRadius.circular(4),
              backgroundColor: AppTheme.getBorderColor(context),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    InfoChip(
                      label: app.category,
                      icon: Icons.category_outlined,
                    ),
                    if (app.isSystemApp ?? false)
                      const InfoChip(
                        label: "Sistema",
                        icon: Icons.settings_applications,
                      ),
                  ],
                ),
                const Divider(height: 24),
                DetailRow(
                  icon: Icons.access_time,
                  text:
                      "Último uso: ${DateFormat('HH:mm').format(app.lastTimeUsed)}",
                ),
                DetailRow(
                  icon: Icons.play_arrow_outlined,
                  text: "Abierta hoy: ${app.launchCount} veces",
                ),
                if (hasFirstUsed)
                  DetailRow(
                    icon: Icons.first_page,
                    text:
                        "Primera vez hoy: ${DateFormat('HH:mm').format(firstUsed)}",
                  ),
                DetailRow(
                  icon: Icons.timer_outlined,
                  text: "${app.avgLabel}: ${app.avgText}",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}