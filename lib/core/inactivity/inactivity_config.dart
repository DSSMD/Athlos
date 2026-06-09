// ============================================================================
// inactivity_config.dart
// Ubicación: lib/core/inactivity/inactivity_config.dart
// Descripción: Constantes del sistema de inactividad.
// Centraliza timeouts y mensajes para ajustar sin tocar lógica.
// @denshel: si preferís esta carpeta en otro lado (ej: lib/core/security/),
// moverla libremente — no hay lógica de negocio, solo constantes.
// ============================================================================

class InactivityConfig {
  InactivityConfig._();

  /// Tiempo de inactividad antes del auto-logout.
  /// Según JIRA SCRUM-58: 30 minutos.
  static const Duration timeoutDuration = Duration(minutes: 30);

  /// Mensaje mostrado al usuario tras el auto-logout.
  static const String expiredSessionMessage =
      'Tu sesión expiró por inactividad. Ingresá de nuevo para continuar.';

  /// Duración del snackbar "Sesión expirada".
  static const Duration snackbarDuration = Duration(seconds: 5);

  /// Para testing: cambiar a `true` y la app usa `debugTimeout` (15s)
  /// en vez de 30 min. Útil para probar sin esperar.
  /// ⚠️ DEJAR EN `false` ANTES DEL MERGE.
  static const bool debugMode = false;
  static const Duration debugTimeout = Duration(seconds: 15);

  /// Timeout efectivo — si está en modo debug, usa el corto.
  static Duration get effectiveTimeout =>
      debugMode ? debugTimeout : timeoutDuration;
}
