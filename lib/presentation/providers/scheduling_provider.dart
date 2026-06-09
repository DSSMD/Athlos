// ============================================================================
// lib/presentation/providers/scheduling_provider.dart
// ============================================================================
// Providers Riverpod para el módulo de Scheduling (Moore-Hodgson).
//
// schedulingServiceProvider   : instancia singleton del servicio.
// schedulingStateProvider     : AsyncValue con la lista de resultados.
// schedulingResumenProvider   : resumen derivado (totales, porcentajes).
// ordenesEnRiesgoCountProvider: contador de órdenes con retraso (para badge).
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/scheduling_service.dart';
import '../../domain/models/scheduling_model.dart';

// ── Servicio ─────────────────────────────────────────────────────────────────

final schedulingServiceProvider = Provider<SchedulingService>(
  (_) => SchedulingService(),
);

// ── Estado principal ─────────────────────────────────────────────────────────

/// Notifier que controla el ciclo de vida del scheduling:
///  - [calcular]: carga datos, ejecuta Moore-Hodgson, guarda y retorna resultados.
///  - [limpiar]: resetea el estado a vacío.
class SchedulingNotifier
    extends AsyncNotifier<List<OrdenSchedulingResult>> {
  @override
  Future<List<OrdenSchedulingResult>> build() async => [];

  /// Ejecuta el scheduling completo:
  ///  1. Lee órdenes activas + tiempos desde Supabase.
  ///  2. Lee capacidad del taller (config_produccion).
  ///  3. Corre Moore-Hodgson en Dart.
  ///  4. Persiste resultados en scheduling_resultado.
  ///  5. Actualiza el state con los resultados.
  Future<void> calcular() async {
    state = const AsyncLoading();
    try {
      final service = ref.read(schedulingServiceProvider);

      final ordenes = await service.obtenerOrdenesParaScheduling();
      final capacidad = await service.obtenerCapacidadHorasDia();
      final resultados = service.ejecutarMooreHodgson(
        ordenes,
        capacidadHorasDia: capacidad,
      );

      // Guardar en Supabase de manera no bloqueante (si falla no rompe la UI)
      try {
        await service.guardarResultados(resultados);
      } catch (_) {
        // Ignoramos errores de persistencia — los resultados ya están en memoria
      }

      state = AsyncData(resultados);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void limpiar() => state = const AsyncData([]);
}

final schedulingStateProvider =
    AsyncNotifierProvider<SchedulingNotifier, List<OrdenSchedulingResult>>(
  SchedulingNotifier.new,
);

// ── Resumen derivado ─────────────────────────────────────────────────────────

final schedulingResumenProvider = Provider<SchedulingResumen?>((ref) {
  final asyncState = ref.watch(schedulingStateProvider);
  return asyncState.whenOrNull(
    data: (resultados) {
      if (resultados.isEmpty) return null;
      final enTiempo = resultados.where((r) => r.enTiempo).length;
      return SchedulingResumen(
        totalOrdenes: resultados.length,
        ordenesEnTiempo: enTiempo,
        ordenesConRetraso: resultados.length - enTiempo,
        fechaCalculo: DateTime.now(),
      );
    },
  );
});

/// Conteo de órdenes en riesgo (tarde). Usado para el badge en la UI de producción.
final ordenesEnRiesgoCountProvider = Provider<int>((ref) {
  final resumen = ref.watch(schedulingResumenProvider);
  return resumen?.ordenesConRetraso ?? 0;
});
