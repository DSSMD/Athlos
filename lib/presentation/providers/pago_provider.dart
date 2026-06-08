// lib/presentation/providers/pago_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/pago_service.dart';
import '../../domain/models/pago_trabajador_model.dart';

// ── Servicio ───────────────────────────────────────────────────────────────────
final pagoServiceProvider = Provider<PagoService>((ref) => PagoService());

// ── Resumen de pagos de producción de UNA orden (usa la VIEW) ─────────────────
// Usado en OrdenDetallePage → OrdenProduccionPagosCard
final resumenPagosOrdenProvider = FutureProvider.family<
    List<ResumenPagoProduccionModel>, String>((ref, numOrden) async {
  final service = ref.read(pagoServiceProvider);
  return service.getResumenPagosPorOrden(numOrden);
});

// ── Historial de pagos de un trabajador en una orden específica ───────────────
// Clave compuesta: 'idTrabajador|numOrden'
final pagosTrabajadorEnOrdenProvider = FutureProvider.family<
    List<PagoTrabajadorModel>, String>((ref, clave) async {
  final parts = clave.split('|');
  if (parts.length < 2) return [];
  final idTrabajador = parts[0];
  final numOrden = parts[1];
  final service = ref.read(pagoServiceProvider);
  return service.getPagosPorTrabajadorEnOrden(idTrabajador, numOrden);
});

// ── Saldos globales de TODOS los trabajadores (para UsuariosPage) ─────────────
final saldosGlobalesTrabajadoresProvider =
    FutureProvider<List<ResumenPagoProduccionModel>>((ref) async {
  final service = ref.read(pagoServiceProvider);
  return service.getSaldosGlobalesTrabajadores();
});

// ── Notifier para registrar pagos (con invalidación reactiva) ─────────────────
class RegistrarPagoNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> registrar({
    required String idTrabajador,
    required double monto,
    required String tipoPago,
    String? idAsignacion,
    String? notas,
    // numOrden se usa para invalidar el provider de resumen al terminar
    String? numOrden,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(pagoServiceProvider);
      await service.registrarPago(
        idTrabajador: idTrabajador,
        monto: monto,
        tipoPago: tipoPago,
        idAsignacion: idAsignacion,
        notas: notas,
      );

      // Invalidamos los providers relevantes para que la UI se refresque sola
      if (numOrden != null) {
        ref.invalidate(resumenPagosOrdenProvider(numOrden));
        ref.invalidate(
          pagosTrabajadorEnOrdenProvider('$idTrabajador|$numOrden'),
        );
      }
      ref.invalidate(saldosGlobalesTrabajadoresProvider);
    });
  }
}

final registrarPagoProvider =
    AsyncNotifierProvider<RegistrarPagoNotifier, void>(
  RegistrarPagoNotifier.new,
);
