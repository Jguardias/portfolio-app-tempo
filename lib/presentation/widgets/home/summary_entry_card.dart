import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tempo/config/theme/app_theme.dart';
import 'package:tempo/presentation/providers/settings/pro_provider.dart';

class SummaryEntryCard extends ConsumerWidget {
  const SummaryEntryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isProProvider);
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.getTileColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.getBorderColor(context)),
        ),
        child: ListTile(
          onTap: () => context.push('/summary'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: Icon(Icons.insights_rounded, color: primary),
          title: const Text('Tus motivos',
              style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Lo que dijiste en tus pausas · últimos 7 días'),
              if (!isPro)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Resumen básico gratis',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: AppTheme.textSegundary,
          ),
        ),
      ),
    );
  }
}