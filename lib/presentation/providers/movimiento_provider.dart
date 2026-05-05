// MOCK — reemplazar con conexión real a Supabase cuando exista tabla
// `movimiento_insumo`. El provider mantiene la lista en memoria, y al crear
// un movimiento ajusta el stock del insumo correspondiente vía
// inventarioProvider.notifier.actualizarStock.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/movimiento_service.dart';
import '../../domain/models/inventario_item_model.dart';
import '../../domain/models/movimiento_model.dart';
import 'inventario_provider.dart';

final movimientoServiceProvider = Provider<MovimientoService>((ref) {
  return MovimientoService();
});

final movimientoProvider =
    AsyncNotifierProvider<MovimientoNotifier, List<MovimientoModel>>(
      MovimientoNotifier.new,
    );

class MovimientoNotifier extends AsyncNotifier<List<MovimientoModel>> {
  @override
  Future<List<MovimientoModel>> build() async {
    return _fetch();
  }

  Future<List<MovimientoModel>> _fetch() async {
    final service = ref.read(movimientoServiceProvider);
    return service.obtenerMovimientos();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  /// Crea un movimiento y ajusta el stock del insumo afectado.
  /// Ingreso → suma cantidad al stock; Salida → resta.
  Future<MovimientoModel> crearMovimiento({
    required InventarioItemModel insumo,
    required TipoMovimiento tipo,
    required double cantidad,
    required String motivo,
    required String usuario,
  }) async {
    final service = ref.read(movimientoServiceProvider);
    final movimiento = await service.crearMovimiento(
      idInsumo: insumo.id,
      tipo: tipo,
      cantidad: cantidad,
      motivo: motivo,
      usuario: usuario,
    );

    // Ajustar stock del insumo en inventarioProvider.
    final delta = tipo == TipoMovimiento.ingreso ? cantidad : -cantidad;
    final nuevoStock = insumo.stockActual + delta;
    ref
        .read(inventarioProvider.notifier)
        .actualizarStock(insumo.id, nuevoStock);

    // Refrescar lista local de movimientos.
    final actuales = state.value ?? const <MovimientoModel>[];
    state = AsyncValue.data([...actuales, movimiento]);

    return movimiento;
  }
}

/// Movimientos filtrados por insumo, ordenados de más reciente a más antiguo.
final movimientosPorInsumoProvider =
    Provider.family<List<MovimientoModel>, String>((ref, idInsumo) {
      final asyncList = ref.watch(movimientoProvider);
      final all = asyncList.value ?? const <MovimientoModel>[];
      final filtered = all.where((m) => m.idInsumo == idInsumo).toList();
      filtered.sort((a, b) => b.fecha.compareTo(a.fecha));
      return filtered;
    });
