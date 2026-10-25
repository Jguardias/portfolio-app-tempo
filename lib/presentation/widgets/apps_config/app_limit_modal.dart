import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tempo/config/theme/app_theme.dart';
import 'package:tempo/domain/entities/app_rule.dart';
import 'package:tempo/presentation/providers/appRules/app_rules_provider.dart';

class AppLimitModal extends ConsumerStatefulWidget {
  final Map<String, dynamic> appData;

  const AppLimitModal({super.key, required this.appData});

  @override
  ConsumerState<AppLimitModal> createState() => _AppLimitModalState();
}

class _AppLimitModalState extends ConsumerState<AppLimitModal> {
  static const int _minValue = 1;
  static const int _maxInitial = 720;
  static const int _maxRepeat = 240;

  static const List<int> _initialPresets = [15, 30, 45, 60];
  static const List<int> _repeatPresets = [5, 10, 15, 20];

  late int _initialMinutes;
  late int _repeatMinutes;
  late bool _initialIsCustom;
  late bool _repeatIsCustom;

  late final TextEditingController _initialController;
  late final TextEditingController _repeatController;

  @override
  void initState() {
    super.initState();
    _initialMinutes =
        (widget.appData['initialThresholdMinutes'] as int?) ?? 30;
    _repeatMinutes = (widget.appData['repeatIntervalMinutes'] as int?) ?? 10;

    // Si el valor guardado no es uno de los predefinidos, se muestra como "Otro"
    _initialIsCustom = !_initialPresets.contains(_initialMinutes);
    _repeatIsCustom = !_repeatPresets.contains(_repeatMinutes);

    _initialController = TextEditingController(
        text: _initialIsCustom ? '$_initialMinutes' : '');
    _repeatController =
        TextEditingController(text: _repeatIsCustom ? '$_repeatMinutes' : '');
  }

  @override
  void dispose() {
    _initialController.dispose();
    _repeatController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _initialMinutes >= _minValue &&
      _initialMinutes <= _maxInitial &&
      _repeatMinutes >= _minValue &&
      _repeatMinutes <= _maxRepeat;

  @override
  Widget build(BuildContext context) {
    final appName = (widget.appData['appName'] as String?) ?? 'Aplicación';
    final packageName = widget.appData['packageName'] as String;
    final Uint8List? iconBytes = widget.appData['iconBytes'] as Uint8List?;
    final primary = Theme.of(context).colorScheme.primary;

    return Padding(
      // Sube el modal cuando aparece el teclado
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.getBackgroundColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Encabezado con el ícono de la app
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: iconBytes != null
                          ? Image.memory(iconBytes,
                              width: 48, height: 48, fit: BoxFit.cover)
                          : Icon(Icons.apps, size: 48, color: primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "Define cuándo y cada cuánto te avisamos",
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSegundary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                _LimitCard(
                  icon: Icons.timer_outlined,
                  title: "Primer aviso",
                  description: "Cuando llegues a este tiempo de uso hoy",
                  value: _initialMinutes,
                  presets: _initialPresets,
                  isCustom: _initialIsCustom,
                  controller: _initialController,
                  min: _minValue,
                  max: _maxInitial,
                  onPreset: (preset) => setState(() {
                    _initialIsCustom = false;
                    _initialMinutes = preset;
                  }),
                  onCustom: () => setState(() {
                    _initialIsCustom = true;
                    _initialController.text =
                        _initialMinutes > 0 ? '$_initialMinutes' : '';
                  }),
                  onChanged: (text) => setState(
                      () => _initialMinutes = int.tryParse(text) ?? 0),
                ),

                const SizedBox(height: 12),

                _LimitCard(
                  icon: Icons.repeat_rounded,
                  title: "Repetir aviso",
                  description: "Si sigues usándola, te avisamos cada",
                  value: _repeatMinutes,
                  presets: _repeatPresets,
                  isCustom: _repeatIsCustom,
                  controller: _repeatController,
                  min: _minValue,
                  max: _maxRepeat,
                  onPreset: (preset) => setState(() {
                    _repeatIsCustom = false;
                    _repeatMinutes = preset;
                  }),
                  onCustom: () => setState(() {
                    _repeatIsCustom = true;
                    _repeatController.text =
                        _repeatMinutes > 0 ? '$_repeatMinutes' : '';
                  }),
                  onChanged: (text) =>
                      setState(() => _repeatMinutes = int.tryParse(text) ?? 0),
                ),

                const SizedBox(height: 16),

                // Resumen en lenguaje natural
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 18, color: primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _isValid
                              ? "Te avisaremos al llegar a $_initialMinutes min de uso hoy y luego cada $_repeatMinutes min mientras sigas en la app."
                              : "Escribe un valor válido para continuar.",
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isValid
                        ? () async {
                            final newRule = AppRule(
                              packageName: packageName,
                              isEnabled: true,
                              initialThresholdMinutes: _initialMinutes,
                              repeatIntervalMinutes: _repeatMinutes,
                            );

                            await ref
                                .read(appRulesProvider.notifier)
                                .saveRule(newRule);

                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          }
                        : null,
                    child: const Text(
                      "Guardar",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LimitCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final int value;
  final List<int> presets;
  final bool isCustom;
  final TextEditingController controller;
  final int min;
  final int max;
  final void Function(int) onPreset;
  final VoidCallback onCustom;
  final void Function(String) onChanged;

  const _LimitCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.presets,
    required this.isCustom,
    required this.controller,
    required this.min,
    required this.max,
    required this.onPreset,
    required this.onCustom,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final bool invalid = isCustom && (value < min || value > max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getTileColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.getBorderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                value > 0 ? "$value min" : "— min",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: invalid ? Colors.redAccent : primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.textSegundary,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ...presets.map(
                (preset) => ChoiceChip(
                  label: Text("$preset min"),
                  selected: !isCustom && value == preset,
                  onSelected: (_) => onPreset(preset),
                ),
              ),
              ChoiceChip(
                label: const Text("Otro"),
                selected: isCustom,
                onSelected: (_) => onCustom(),
              ),
            ],
          ),
          if (isCustom) ...[
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              decoration: InputDecoration(
                labelText: "Minutos",
                suffixText: "min",
                errorText: invalid ? "Escribe un valor entre $min y $max" : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: onChanged,
            ),
          ],
        ],
      ),
    );
  }
}