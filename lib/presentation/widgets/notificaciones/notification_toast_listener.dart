// ============================================================================
// lib/presentation/widgets/notificaciones/notification_toast_listener.dart
// ============================================================================
// Listener global de toasts: cuando llega una notificación nueva (no vista
// y no leída) dispara un SnackBar flotante con NotificationToast adentro.
//
// Vive envolviendo el body del Scaffold en main_layout.dart para tener
// acceso a ScaffoldMessenger.of(context). Watchea notificacionesProvider y
// compara la lista contra los ids ya vistos en _seenIds.
//
// Por qué Set<String> y no List<String>:
//   - Lookup O(1) vs O(n). Cuando la lista crezca a decenas de notificaciones
//     el check `seen.contains(id)` corre por cada item de cada update —
//     un Set evita degradación cuadrática.
//
// Por qué la flag _initialized:
//   - Al cargar la app el provider entrega la lista completa de notifs
//     existentes en su primera resolución. Sin la flag, lanzaríamos un toast
//     por cada una de esas — un "barrage" de SnackBars apilados nada más
//     entrar. La primera entrega solo siembra _seenIds; recién a partir de
//     la segunda entrega (típicamente disparada por Realtime) salen toasts.
//
// Cola de toasts:
//   - ScaffoldMessenger encola SnackBars automáticamente. No armamos cola
//     propia — si llegan 3 notificaciones seguidas Material las muestra
//     una atrás de otra al cerrar la anterior (manual o por timeout).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/notificacion_model.dart';
import '../../providers/notificacion_provider.dart';
import 'notification_toast.dart';

class NotificationToastListener extends ConsumerStatefulWidget {
  const NotificationToastListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationToastListener> createState() =>
      _NotificationToastListenerState();
}

class _NotificationToastListenerState
    extends ConsumerState<NotificationToastListener> {
  final Set<String> _seenIds = <String>{};
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<NotificacionModel>>>(notificacionesProvider, (
      previous,
      next,
    ) {
      if (!next.hasValue) return;
      final lista = next.value!;

      // Primera entrega: sembramos los ids como vistos para evitar
      // disparar toasts por las notifs históricas al arrancar la app.
      if (!_initialized) {
        _seenIds.addAll(lista.map((n) => n.idNotificacion));
        _initialized = true;
        return;
      }

      // Entregas posteriores: por cada notif que no hayamos visto y que
      // venga marcada como no-leída, disparamos un toast y la sumamos al
      // set para que próximos updates no la repitan.
      for (final n in lista) {
        if (_seenIds.contains(n.idNotificacion)) continue;
        _seenIds.add(n.idNotificacion);
        if (n.leida) continue;
        _showToast(n);
      }
    });

    return widget.child;
  }

  void _showToast(NotificacionModel n) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: NotificationToast(
          notificacion: n,
          onClose: () => messenger.hideCurrentSnackBar(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
