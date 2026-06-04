// ============================================================================
// lib/presentation/providers/notificacion_provider.dart
// ============================================================================
// Riverpod providers del módulo Notificaciones.
//
// Expone:
//   - notificacionServiceProvider: singleton del service.
//   - notificacionesProvider: AsyncNotifier con la lista del usuario actual.
//   - unreadNotificacionesCountProvider: contador derivado para el badge.
//
// Resolución del usuario actual:
//   - Se lee de `userProfileProvider` (auth_provider.dart). Si no hay sesión
//     o el id no está poblado, devolvemos lista vacía sin tirar error — la
//     UI debería mostrar el bell en estado guest y no debería ver errores.
//
// Updates optimistas:
//   - marcarLeida / marcarTodasLeidas mutan el state localmente ANTES de
//     llamar al service. Si el service falla, invalidamos para refrescar
//     desde BD. Con `_useMockData = true` en el service el update local es
//     suficiente para que UI/badge respondan; cuando se prenda el modo real,
//     la consistencia eventual la garantiza obtenerNotificaciones.
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/notificacion_service.dart';
import '../../domain/models/notificacion_model.dart';
import 'auth_provider.dart';

// ─── SERVICE ──────────────────────────────────────────────────────────────────

final notificacionServiceProvider = Provider<NotificacionService>((ref) {
  return NotificacionService();
});

// ─── NOTIFIER ─────────────────────────────────────────────────────────────────

class NotificacionesNotifier extends AsyncNotifier<List<NotificacionModel>> {
  @override
  Future<List<NotificacionModel>> build() async {
    // ref.watch al userProfileProvider hace que el notifier re-corra build()
    // cuando el usuario logea / cambia sesión / cierra sesión.
    final profileAsync = ref.watch(userProfileProvider);
    final userId = profileAsync.value?['id']?.toString();
    if (userId == null || userId.isEmpty) {
      return const [];
    }

    final service = ref.read(notificacionServiceProvider);
    return service.obtenerNotificaciones(userId);
  }

  /// Marca una notificación como leída con update optimista. Si la llamada
  /// al service falla, invalidamos para resincronizar desde BD.
  Future<void> marcarLeida(String idNotificacion) async {
    final current = state.value;
    if (current == null) return;

    // Update optimista: pintamos la UI antes de que la BD confirme.
    state = AsyncData(
      current
          .map(
            (n) => n.idNotificacion == idNotificacion
                ? n.copyWith(leida: true)
                : n,
          )
          .toList(),
    );

    try {
      await ref.read(notificacionServiceProvider).marcarLeida(idNotificacion);
    } catch (_) {
      // Si BD falla, refrescamos para recuperar el estado real.
      ref.invalidateSelf();
    }
  }

  /// Marca todas las no-leídas como leídas. Mismo patrón optimista que
  /// `marcarLeida`, en lote.
  Future<void> marcarTodasLeidas() async {
    final current = state.value;
    if (current == null) return;

    final userId = ref.read(userProfileProvider).value?['id']?.toString();
    if (userId == null || userId.isEmpty) return;

    state = AsyncData(
      current.map((n) => n.leida ? n : n.copyWith(leida: true)).toList(),
    );

    try {
      await ref.read(notificacionServiceProvider).marcarTodasLeidas(userId);
    } catch (_) {
      ref.invalidateSelf();
    }
  }
}

final notificacionesProvider =
    AsyncNotifierProvider<NotificacionesNotifier, List<NotificacionModel>>(
      NotificacionesNotifier.new,
    );

// ─── DERIVADOS ────────────────────────────────────────────────────────────────

/// Contador de no-leídas para el badge del bell.
///
/// Devuelve 0 mientras carga o si hay error — la UI no debería mostrar el
/// punto rojo cuando el estado es inestable. Cuando la lista esté lista,
/// cuenta cuántas tienen `leida == false`.
final unreadNotificacionesCountProvider = Provider<int>((ref) {
  final async = ref.watch(notificacionesProvider);
  return async.maybeWhen(
    data: (list) => list.where((n) => !n.leida).length,
    orElse: () => 0,
  );
});
