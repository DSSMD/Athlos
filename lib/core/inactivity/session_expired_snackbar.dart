// ============================================================================
// session_expired_snackbar.dart
// Ubicación: lib/core/inactivity/session_expired_snackbar.dart
// Descripción: SnackBar "Sesión expirada" que se muestra tras el auto-logout.
//
// Se invoca como: SessionExpiredSnackbar.show();
// Requiere que MaterialApp.router tenga asignado `rootScaffoldMessengerKey`
// para poder mostrar el SnackBar desde fuera del árbol normal de widgets.
//
// NOTA: colores y tipografía están hardcodeados provisoriamente porque el
// design system de UI-02 aún no está mergeado en develop. Cuando se mergee,
// refactorizar para usar AppColors y AppTypography.
// ============================================================================

import 'package:flutter/material.dart';
import 'inactivity_config.dart';

/// Key global que se debe asignar al MaterialApp.router.
/// Permite mostrar snackbars desde cualquier parte de la app.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class SessionExpiredSnackbar {
  SessionExpiredSnackbar._();

  /// Colores provisorios — alinear al design system cuando se mergee UI-02.
  static const _bgColor = Color(0xFF0A0A0A);
  static const _accentColor = Color(0xFFFF0000);
  static const _titleColor = Color(0xFFFFFFFF);
  static const _bodyColor = Color(0xFFE5E5E5);

  /// Muestra el snackbar "Sesión expirada".
  /// Llamar DESPUÉS de signOut para que el router ya haya redirigido al login.
  static void show() {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: InactivityConfig.snackbarDuration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: _bgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        content: Row(
          children: [
            const Icon(
              Icons.lock_clock_outlined,
              color: _accentColor,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sesión expirada',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: _titleColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    InactivityConfig.expiredSessionMessage,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: _bodyColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}