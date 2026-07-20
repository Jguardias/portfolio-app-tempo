import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tempo/config/theme/app_theme.dart';
import 'package:tempo/domain/entities/app_usage.dart';
import 'package:tempo/domain/entities/app_usage_extensions.dart';
import 'package:tempo/presentation/widgets/home/app_info_widgets.dart';

class AppUsageTile extends StatelessWidget {
  final AppUsage app;

  const AppUsageTile({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ExpansionTile(
        backgroundColor: AppTheme.getTileColor(context),
        collapsedBackgroundColor: AppTheme.getTileColor(context),
        shape: RoundedRectangleBorder(
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
        subtitle: Text(app.formattedDuration), // <--- USANDO LA EXTENSIÓN
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
                  text: "Último uso: ${DateFormat('HH:mm').format(app.lastTimeUsed)}",
                ),
                DetailRow(
                  icon: Icons.play_arrow_outlined,
                  text: "Abierta hoy: ${app.launchCount} veces",
                ),
                DetailRow(
                  icon: Icons.first_page,
                  text: "Primera vez hoy: ${DateFormat('HH:mm').format(app.firstUsed!)}",
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