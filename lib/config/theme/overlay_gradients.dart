import 'dart:math';
import 'package:flutter/material.dart';

abstract class OverlayGradients {
  static const List<LinearGradient> presets = [
   
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF0284C7)],
    ),
    
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF4C1D95), Color(0xFF6D28D9), Color(0xFF8B5CF6)],
    ),
    
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF10B981)],
    ),
  
    LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF881337), Color(0xFFBE123C), Color(0xFFF43F5E)],
    ),
  ];

  static LinearGradient getRandom() {
    final random = Random();
    return presets[random.nextInt(presets.length)];
  }
}