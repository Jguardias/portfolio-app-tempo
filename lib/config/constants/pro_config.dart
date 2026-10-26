class ProConfig {
  /// Mientras sea true, todas las funciones Pro están abiertas (pruebas cerradas).
  /// Cámbialo a false cuando se integre el cobro real.
  static const bool unlockedForTesting = true;

  /// Apps con pausa activa a la vez en la versión gratuita.
  static const int freeAppLimit = 3;
}