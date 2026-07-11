import 'package:flutter/material.dart';

class AppTheme {
 
  static const Color background = Color(0xFFF8F9FB);
  static const Color textSegundary = Colors.grey;
  static const Color backgroundTile = Colors.white;
  static const Color colorBorderTileExpanded = Color.fromARGB(255, 242, 242, 242);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkBackgroundTile = Color(0xFF1E1E1E);
  static const Color darkBorder = Color(0xFF2C2C2C);
  static const Color darkTextSecondary = Colors.grey; 


  static Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkBackground 
        : background;
  }

  static Color getTileColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkBackgroundTile 
        : backgroundTile;
  }

  static Color getBorderColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark 
        ? darkBorder 
        : colorBorderTileExpanded;
  }

  ThemeData getTheme(Brightness brightness) => ThemeData(
        useMaterial3: true,
        brightness: brightness,
        colorSchemeSeed: Colors.blueAccent,
      );
}