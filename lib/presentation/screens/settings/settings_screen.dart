import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tempo/config/theme/app_theme.dart';
import 'package:tempo/presentation/providers/settings/theme_mode_provider.dart';
import 'package:tempo/presentation/widgets/shared/section_header.dart';

class SettingsScreen extends ConsumerWidget {
  static const name = 'settings-screen';

  /// Actualízala junto con la versión del pubspec.yaml.
  static const String appVersion = '0.1.0';

  const SettingsScreen({super.key});

  void _showInfo(
    BuildContext context, {
    required String title,
    required String body,
    bool offerAppSettings = false,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(body)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
          if (offerAppSettings)
            FilledButton(
              onPressed: () {
                Navigator.pop(ctx);
                openAppSettings();
              },
              child: const Text('Abrir ajustes'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            const SectionHeader(
              title: "Ajustes",
              subtitle: "Personaliza Tempo y consulta información de la app.",
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _Group(
                    label: 'Apariencia',
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tema',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: SegmentedButton<ThemeMode>(
                                showSelectedIcon: false,
                                segments: const [
                                  ButtonSegment(
                                    value: ThemeMode.system,
                                    icon: Icon(Icons.brightness_auto_rounded),
                                    label: Text('Auto'),
                                  ),
                                  ButtonSegment(
                                    value: ThemeMode.light,
                                    icon: Icon(Icons.light_mode_rounded),
                                    label: Text('Claro'),
                                  ),
                                  ButtonSegment(
                                    value: ThemeMode.dark,
                                    icon: Icon(Icons.dark_mode_rounded),
                                    label: Text('Oscuro'),
                                  ),
                                ],
                                selected: {themeMode},
                                onSelectionChanged: (selection) => ref
                                    .read(themeModeProvider.notifier)
                                    .setMode(selection.first),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  _Group(
                    label: 'Funcionamiento',
                    children: [
                      _SettingsTile(
                        icon: Icons.battery_saver_rounded,
                        title: 'Mantener Tempo funcionando',
                        subtitle: 'Batería, inicio automático y permisos',
                        onTap: () => _showInfo(
                          context,
                          title: 'Mantener Tempo funcionando',
                          offerAppSettings: true,
                          body:
                              'Algunos teléfonos cierran las apps en segundo plano para ahorrar batería. '
                              'Si los avisos dejan de aparecer:\n\n'
                              '1. Abre los ajustes de Tempo (botón de abajo).\n'
                              '2. En Batería, elige "Sin restricciones".\n'
                              '3. En Xiaomi, activa también "Inicio automático".\n'
                              '4. En Samsung, quita Tempo de las apps en suspensión.\n\n'
                              'Los nombres exactos cambian según la marca y la versión de Android.',
                        ),
                      ),
                    ],
                  ),
                  _Group(
                    label: 'Información',
                    children: [
                      _SettingsTile(
                        icon: Icons.lightbulb_outline_rounded,
                        title: 'Cómo funciona Tempo',
                        onTap: () => _showInfo(
                          context,
                          title: 'Cómo funciona Tempo',
                          body:
                              'Activa una app en la pestaña Aplicaciones y elige cuánto tiempo de uso al día quieres '
                              'permitirte antes del primer aviso.\n\n'
                              'Cuando llegues a ese tiempo, Tempo te mostrará una pausa para que decidas con intención '
                              'si quieres seguir. Si continúas, te volverá a avisar con la frecuencia que definiste.',
                        ),
                      ),
                      const Divider(height: 1),
                      _SettingsTile(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacidad',
                        onTap: () => _showInfo(
                          context,
                          title: 'Privacidad',
                          body:
                              'Tempo guarda tus reglas y pausas solo en tu dispositivo. No tiene cuentas, no usa '
                              'internet y no envía tus datos a ningún servidor.\n\n'
                              'Usa el permiso de estadísticas de uso para medir el tiempo que pasas en cada app, y el '
                              'permiso de mostrar sobre otras apps para el aviso de pausa.',
                        ),
                      ),
                      const Divider(height: 1),
                      _SettingsTile(
                        icon: Icons.description_outlined,
                        title: 'Licencias de código abierto',
                        onTap: () => showLicensePage(
                          context: context,
                          applicationName: 'Tempo',
                          applicationVersion: appVersion,
                        ),
                      ),
                      const Divider(height: 1),
                      const _SettingsTile(
                        icon: Icons.info_outline_rounded,
                        title: 'Versión',
                        subtitle: appVersion,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final String label;
  final List<Widget> children;

  const _Group({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSegundary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.getTileColor(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.getBorderColor(context)),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: onTap == null
          ? null
          : const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textSegundary,
            ),
    );
  }
}