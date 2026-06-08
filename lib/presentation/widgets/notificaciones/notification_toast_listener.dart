// ============================================================================
// lib/presentation/widgets/notificaciones/notification_toast_listener.dart
// ============================================================================
import 'dart:async'; // 🔥 IMPORTANTE PARA LA SUSCRIPCIÓN
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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

  // 🔥 VARIABLE PARA GUARDAR EL "ESCUCHADOR"
  StreamSubscription<RemoteMessage>? _foregroundSubscription;

  @override
  void initState() {
    super.initState();
    // ------------------------------------------------------------------------
    // GUARDAMOS LA SUSCRIPCIÓN PARA PODER CERRARLA DESPUÉS
    // ------------------------------------------------------------------------
    _foregroundSubscription = FirebaseMessaging.onMessage.listen((
      RemoteMessage message,
    ) {
      if (message.notification != null) {
        final n = NotificacionModel(
          idNotificacion: message.messageId ?? DateTime.now().toString(),
          idUsuario: 'app_active',
          titulo: message.notification!.title ?? 'Sin título',
          mensaje: message.notification!.body ?? '',
          leida: false,
          fechaCreacion: DateTime.now(),
          prioridad:
              PrioridadNotificacion.informativa, // O ajustarlo según el data
        );
        _showToast(n);
      }
    });
  }

  // 🔥 ESTO EVITA QUE TENGAS TOASTS REPETIDOS O FUGAS DE MEMORIA
  @override
  void dispose() {
    _foregroundSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // LÓGICA DE REALTIME INTACTA
    ref.listen<AsyncValue<List<NotificacionModel>>>(notificacionesProvider, (
      previous,
      next,
    ) {
      if (!next.hasValue) return;
      final lista = next.value!;

      if (!_initialized) {
        _seenIds.addAll(lista.map((n) => n.idNotificacion));
        _initialized = true;
        return;
      }

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
