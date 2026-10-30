class ProConfig {
  /// Solo se activa al compilar con:  flutter build appbundle --release --dart-define=TEMPO_UNLOCKED=true
  /// Por defecto es false, así que un build normal (producción) nunca regala Pro.
  static const bool unlockedForTesting =
      bool.fromEnvironment('TEMPO_UNLOCKED', defaultValue: false);

  /// Apps con pausa activa a la vez en la versión gratuita.
  static const int freeAppLimit = 3;

  /// ID del producto en Play Console (debe ser idéntico).
  static const String productId = 'tempo_pro';
}