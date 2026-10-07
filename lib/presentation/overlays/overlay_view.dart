import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:tempo/config/theme/overlay_gradients.dart';
import 'package:tempo/infrastructure/datasources/app_rules_local_datasource_impl.dart';
import 'package:tempo/infrastructure/services/quote_service.dart';

class TempoOverlayScreen extends StatefulWidget {
  const TempoOverlayScreen({super.key});

  @override
  State<TempoOverlayScreen> createState() => _TempoOverlayScreenState();
}

class _TempoOverlayScreenState extends State<TempoOverlayScreen> {
  late  String _quote;
  late  LinearGradient _gradient;
  final _rulesDatasource = AppRulesLocalDatasourceImpl();

  @override
  void initState() {
    super.initState();
    _quote = QuoteService().getRandomQuote();
    _gradient = OverlayGradients.getRandom();
  }

  void _loadNewContent() {
    _quote = QuoteService().getRandomQuote();
    _gradient = OverlayGradients.getRandom();
    print(" [Overlay] Nueva frase preparada: $_quote");
  }

  /// Registra el tiempo de pausa (Snooze) antes de cerrar la ventana
  Future<void> _continueWithIntention(String? packageName, int repeatIntervalMinutes) async {
    if (packageName != null && packageName.isNotEmpty) {
      final existingRule = await _rulesDatasource.getRuleForPackage(packageName);
      if (existingRule != null) {
        final updatedRule = existingRule.copyWith(
          snoozedUntil: DateTime.now().add(Duration(minutes: repeatIntervalMinutes)),
        );
        await _rulesDatasource.saveRule(updatedRule);
      }
    }
    setState(() {
   _loadNewContent();
  });
    await FlutterOverlayWindow.closeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Center(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: _gradient,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 25,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(26.0),
                child: StreamBuilder<dynamic>(
                  stream: FlutterOverlayWindow.overlayListener,
                  builder: (context, snapshot) {
                    final data = snapshot.data;
                    
                    final String? packageName = (data is Map && data['packageName'] != null)
                        ? data['packageName'].toString()
                        : null;

                    final String appName = (data is Map && data['appName'] != null)
                        ? data['appName'].toString()
                        : "esta aplicación";

                    final int repeatIntervalMinutes = (data is Map && data['repeatIntervalMinutes'] != null)
                        ? (data['repeatIntervalMinutes'] as int)
                        : 10;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const _GlassIcon(icon: Icons.access_time_filled_rounded),
                            _GlassIconButton(
                              icon: Icons.close_rounded,
                              onTap: () => _continueWithIntention(packageName, repeatIntervalMinutes),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Text(
                          "¿Sigue siendo tu intención estar en $appName?",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.1,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _quote,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            height: 1.3,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: _gradient.colors.first,
                              elevation: 3,
                              shadowColor: Colors.black26,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () => _continueWithIntention(packageName, repeatIntervalMinutes),
                            child: const Text(
                              "Continuar con intención",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: Text(
                            "Te volveremos a avisar en $repeatIntervalMinutes minutos.",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassIcon extends StatelessWidget {
  final IconData icon;

  const _GlassIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}