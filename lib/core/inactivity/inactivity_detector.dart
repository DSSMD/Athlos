// ============================================================================
// inactivity_detector.dart
// Ubicación: lib/core/inactivity/inactivity_detector.dart
// Descripción: Widget que detecta actividad del usuario (taps, scroll, mouse,
// keyboard) y ejecuta un callback al superarse el timeout de inactividad.
//
// Uso (en main.dart, envolviendo MaterialApp.router):
//
//   InactivityDetector(
//     enabled: isLoggedIn,
//     onInactive: () async {
//       await Supabase.instance.client.auth.signOut();
//       // El router de Denshel reacciona solo y redirige a /login.
//       SessionExpiredSnackbar.show();
//     },
//     child: MaterialApp.router(...),
//   )
//
// El detector se desactiva cuando `enabled: false` (ej: el usuario ya no
// tiene sesión) para no consumir recursos.
// ============================================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'inactivity_config.dart';

class InactivityDetector extends StatefulWidget {
  const InactivityDetector({
    super.key,
    required this.child,
    required this.onInactive,
    this.enabled = true,
    this.timeout,
  });

  /// Widget hijo (típicamente MaterialApp.router).
  final Widget child;

  /// Callback ejecutado al superarse el timeout.
  final Future<void> Function() onInactive;

  /// Si el detector está activo. Pasar `false` cuando el usuario no tiene
  /// sesión (ej: está en /login) para evitar consumir recursos.
  final bool enabled;

  /// Timeout custom. Por defecto usa InactivityConfig.effectiveTimeout.
  final Duration? timeout;

  @override
  State<InactivityDetector> createState() => _InactivityDetectorState();
}

class _InactivityDetectorState extends State<InactivityDetector> {
  Timer? _timer;
  bool _triggered = false;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) _startTimer();
  }

  @override
  void didUpdateWidget(InactivityDetector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled != oldWidget.enabled) {
      if (widget.enabled) {
        _startTimer();
      } else {
        _cancelTimer();
      }
    }
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────── TIMER ──

  void _startTimer() {
    _cancelTimer();
    _triggered = false;
    final duration = widget.timeout ?? InactivityConfig.effectiveTimeout;
    _timer = Timer(duration, _handleTimeout);
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _resetTimer() {
    if (!widget.enabled || _triggered) return;
    _startTimer();
  }

  Future<void> _handleTimeout() async {
    if (_triggered) return;
    _triggered = true;
    await widget.onInactive();
  }

  // ───────────────────────────────────────────── DETECTORES DE INPUT ──

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return Listener(
      behavior: HitTestBehavior.translucent,
      // Taps y clicks
      onPointerDown: (_) => _resetTimer(),
      // Movimiento de mouse (desktop/web)
      onPointerHover: (_) => _resetTimer(),
      // Scroll con trackpad o mouse wheel
      onPointerSignal: (_) => _resetTimer(),
      child: Focus(
        autofocus: true,
        onKeyEvent: (_, __) {
          _resetTimer();
          return KeyEventResult.ignored;
        },
        child: NotificationListener<ScrollNotification>(
          // Scroll de listas también cuenta
          onNotification: (_) {
            _resetTimer();
            return false;
          },
          child: widget.child,
        ),
      ),
    );
  }
}