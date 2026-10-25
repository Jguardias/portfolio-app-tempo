import 'package:flutter/material.dart';

/// El primer cuadro es idéntico al splash nativo (mismo fondo y mismo logo,
/// centrado). Desde ahí el logo late, se enciende el brillo y entra el texto.
class TempoSplash extends StatefulWidget {
  final VoidCallback onFinished;

  const TempoSplash({super.key, required this.onFinished});

  @override
  State<TempoSplash> createState() => _TempoSplashState();
}

class _TempoSplashState extends State<TempoSplash>
    with SingleTickerProviderStateMixin {
  // Debe coincidir con el color del splash nativo
  static const Color _bg = Color(0xFF0F2C5E);
  static const Color _glow = Color(0xFF2A9DA8);

  late final AnimationController _controller;
  late final Animation<double> _pulse;
  late final Animation<double> _glowAnim;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _pulse = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 50),
    ]).animate(_controller);

    _glowAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    final textCurve = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
    );
    _textFade = textCurve;
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(textCurve);

    _controller.forward().whenComplete(() {
      if (mounted) widget.onFinished();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.6, -0.6),
                    radius: 1.1,
                    colors: [
                      _glow.withValues(alpha: 0.5 * _glowAnim.value),
                      _bg.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
              // Logo exactamente en el centro, como el splash nativo
              Center(
                child: ScaleTransition(
                  scale: _pulse,
                  child: Image.asset(
                    'assets/images/logo_splash.png',
                    width: 250,
                    height: 250,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.hourglass_bottom_rounded,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // Texto debajo del logo, sin mover el logo
              Align(
                alignment: const Alignment(0, 0.36),
                child: FadeTransition(
                  opacity: _textFade,
                  child: SlideTransition(
                    position: _textSlide,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Tempo",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Tu tiempo, con intención.",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 14,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}