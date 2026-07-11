import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:tempo/infrastructure/services/quote_service.dart';

class OverlayContent extends StatefulWidget {
  const OverlayContent({super.key});

  @override
  State<OverlayContent> createState() => _OverlayContentState();
}

class _OverlayContentState extends State<OverlayContent> {
  
  late String frase;

  @override
  void initState() {
    super.initState();
    frase = QuoteService().getRandomQuote();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9), 
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "UN MOMENTO DE PAUSA",
                  style: TextStyle(
                    fontSize: 14, 
                    letterSpacing: 2, 
                    color: Colors.indigo, 
                    fontWeight: FontWeight.bold
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  frase, // 3. Aquí usamos la variable que inicializamos
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                TextButton(
                  onPressed: () async => await FlutterOverlayWindow.closeOverlay(),
                  child: const Text(
                    "Volver a mi presente", 
                    style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)
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