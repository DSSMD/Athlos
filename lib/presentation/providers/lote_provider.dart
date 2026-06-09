import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/lote_service.dart';
import '../../domain/models/lote_model.dart';
import 'orden_provider.dart';

// 1. Inyectamos el Servicio
final loteServiceProvider = Provider<LoteService>((ref) {
  return LoteService();
});

// 2. Provider que obtiene la lista de lotes
final FutureProvider<List<LoteModel>> lotesListProvider = FutureProvider<List<LoteModel>>((ref) async {
  final service = ref.watch(loteServiceProvider);
  final lotes = await service.getLotes();

  // --- Sincronización Automática del Estado de la Orden ---
  try {
    // 1. Agrupamos los lotes por ID de orden
    final Map<String, List<LoteModel>> lotesPorOrden = {};
    for (var lote in lotes) {
      if (lote.ordenId.isNotEmpty && lote.ordenId != 'Sin Orden') {
        if (!lotesPorOrden.containsKey(lote.ordenId)) {
          lotesPorOrden[lote.ordenId] = [];
        }
        lotesPorOrden[lote.ordenId]!.add(lote);
      }
    }

    final ordenService = ref.read(ordenServiceProvider);

    // 2. Evaluamos el estado correcto para cada orden
    for (var entry in lotesPorOrden.entries) {
      final ordenId = entry.key;
      final lotesDeEstaOrden = entry.value;

      final int? currentOrderState = lotesDeEstaOrden.first.idEstadoOrden;
      if (currentOrderState == null) continue;

      // Si ya está Entregada (4), no alteramos su estado
      if (currentOrderState == 4) continue;

      // Determinamos el estado objetivo según sus lotes:
      // - Si todos están 'Terminado', el estado debe ser 3 (Finalizada)
      // - Si al menos uno no es 'Pendiente' (o tiene avance/asignación), el estado debe ser 2 (En Producción)
      // - Si todos están 'Pendiente', el estado debe ser 1 (Pendiente)
      int targetState = 1;
      final bool allFinished = lotesDeEstaOrden.every((l) => l.estado == 'Terminado');

      if (allFinished) {
        targetState = 3;
      } else {
        final bool anyStarted = lotesDeEstaOrden.any((l) => l.estado != 'Pendiente');
        if (anyStarted) {
          targetState = 2;
        }
      }

      // 3. Si hay discrepancia, actualizamos en base de datos de manera asíncrona
      if (currentOrderState != targetState) {
        ordenService.actualizarEstadoOrden(ordenId, targetState).then((_) {
          // Refrescamos el listado de órdenes en el backend
          ref.invalidate(ordenesProvider);
          // print('SYNC ORDER STATE: Orden $ordenId actualizada de $currentOrderState a $targetState con éxito.');
        }).catchError((err) {
          // print('SYNC ORDER STATE ERROR: No se pudo actualizar estado de orden $ordenId: $err');
        });
      }
    }
  } catch (e) {
    // print('SYNC ORDER STATE SYSTEM ERROR: $e');
  }

  // --- Autorefresh periódico (cada 10 segundos) ---
  final timer = Timer(const Duration(seconds: 10), () {
    ref.invalidateSelf();
  });
  ref.onDispose(() {
    timer.cancel();
  });

  return lotes;
});
