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
          subtitle: const Text('Lo que dijiste en tus pausas · últimos 7 días'),
          trailing: Icon(
            isPro ? Icons.chevron_right_rounded : Icons.lock_outline_rounded,
            color: AppTheme.textSegundary,
          ),
        ),
      ),
    );
  }
}