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
  /// El stock antes lo resuelve el notifier leyendo el inventario actual,
  /// el stock después lo calcula el service según el tipo.
  Future<MovimientoModel> crearMovimiento({
    required String idInsumo,
    required TipoMovimiento tipo,
    required double cantidad,
    required String motivo,
    required String usuario,
  }) async {
    // Obtener stock actual del insumo ANTES del movimiento.

    final inventario =
        ref.read(inventarioProvider).value ?? const <InventarioItemModel>[];
    final item = inventario.firstWhere((i) => i.id == idInsumo);
    final stockAntes = item.stockActual;

    final service = ref.read(movimientoServiceProvider);
    final movimiento = await service.crearMovimiento(
      idInsumo: idInsumo,
      tipo: tipo,
      cantidad: cantidad,
      motivo: motivo,
      usuario: usuario,
      stockAntes: stockAntes,
    );

    // 👇 1. FORZAR RECARGA DEL KÁRDEX (Borramos el state manual)
    ref.invalidateSelf();

    // 👇 2. FORZAR RECARGA DEL STOCK DE INSUMOS (Ya lo tenías, ¡está perfecto!)
    ref.invalidate(inventarioProvider);

    return movimiento;
  }
}

// ─── FILTROS DEL TAB MOVIMIENTOS ──────────────────────────────────────────────

class MovimientoFiltros {
  const MovimientoFiltros({this.area, this.tipo, this.query = ''});

  final AreaMovimiento? area;
  final TipoMovimiento? tipo;
  final String query;

  MovimientoFiltros copyWith({
    AreaMovimiento? area,
    TipoMovimiento? tipo,
    String? query,
    bool clearArea = false,
    bool clearTipo = false,
  }) {
    return MovimientoFiltros(
      area: clearArea ? null : (area ?? this.area),
      tipo: clearTipo ? null : (tipo ?? this.tipo),
      query: query ?? this.query,
    );
  }
}

class MovimientoFiltrosNotifier extends Notifier<MovimientoFiltros> {
  @override
  MovimientoFiltros build() => const MovimientoFiltros();

  void setArea(AreaMovimiento? a) {
    state = state.copyWith(area: a, clearArea: a == null);
  }

  void setTipo(TipoMovimiento? t) {
    state = state.copyWith(tipo: t, clearTipo: t == null);
  }

  void setQuery(String q) {
    state = state.copyWith(query: q);
  }

  void limpiar() {
    state = const MovimientoFiltros();
  }
}

final movimientoFiltrosProvider =
    NotifierProvider<MovimientoFiltrosNotifier, MovimientoFiltros>(
      MovimientoFiltrosNotifier.new,
    );

/// Lista filtrada por área/tipo/query, ordenada por fecha desc.
final movimientosFiltradosProvider = Provider<List<MovimientoModel>>((ref) {
  final movimientos =
      ref.watch(movimientoProvider).value ?? const <MovimientoModel>[];
  final inventario =
      ref.watch(inventarioProvider).value ?? const <InventarioItemModel>[];
  final filtros = ref.watch(movimientoFiltrosProvider);
  final q = filtros.query.toLowerCase().trim();

  final result = movimientos.where((m) {
    if (filtros.area != null && m.area != filtros.area) return false;
    if (filtros.tipo != null && m.tipo != filtros.tipo) return false;
    if (q.isNotEmpty) {
      final idx = inventario.indexWhere((i) => i.id == m.idInsumo);
      final nombreInsumo = idx != -1 ? inventario[idx].nombre : '';
      final matchInsumo = nombreInsumo.toLowerCase().contains(q);
      final matchRef = m.referencia.toLowerCase().contains(q);
      final matchMotivo = m.motivo.toLowerCase().contains(q);
      if (!matchInsumo && !matchRef && !matchMotivo) return false;
    }
    return true;
  }).toList();

  result.sort((a, b) => b.fecha.compareTo(a.fecha));
  return result;
});

/// Movimientos filtrados por insumo, ordenados de más reciente a más antiguo.
final movimientosPorInsumoProvider =
    Provider.family<List<MovimientoModel>, String>((ref, idInsumo) {
      final asyncList = ref.watch(movimientoProvider);
      final all = asyncList.value ?? const <MovimientoModel>[];
      final filtered = all.where((m) => m.idInsumo == idInsumo).toList();
      filtered.sort((a, b) => b.fecha.compareTo(a.fecha));
      return filtered;
    });

// ─── KPIs DEL MES ─────────────────────────────────────────────────────────────

class MovimientoKpis {
  const MovimientoKpis({
    required this.entradasMes,
    required this.salidasMes,
    required this.automaticosMes,
    required this.ajustesMes,
    required this.valorComprasMes,
  });

  final int entradasMes;
  final int salidasMes;
  final int automaticosMes;
  final int ajustesMes;
  final double valorComprasMes;
}

/// KPIs del mes calendario actual derivados de movimientoProvider +
/// inventarioProvider (para calcular valor monetario de las compras).
final movimientoKpisProvider = Provider<MovimientoKpis>((ref) {
  final movimientos =
      ref.watch(movimientoProvider).value ?? const <MovimientoModel>[];
  final inventario =
      ref.watch(inventarioProvider).value ?? const <InventarioItemModel>[];

  final ahora = DateTime.now();
  final inicioMes = DateTime(ahora.year, ahora.month, 1);
  final mesActual = movimientos.where((m) => !m.fecha.isBefore(inicioMes));

  var entradas = 0;
  var salidas = 0;
  var automaticos = 0;
  var ajustes = 0;
  var valorCompras = 0.0;

  for (final m in mesActual) {
    switch (m.tipo) {
      case TipoMovimiento.ingreso:
        entradas++;
        // Valor en bolivianos: cantidad * costo unitario del insumo.
        final idx = inventario.indexWhere((i) => i.id == m.idInsumo);
        if (idx != -1) {
          valorCompras += m.cantidad * inventario[idx].costoUnitario;
        }
        break;
      case TipoMovimiento.salida:
        salidas++;
        break;
      case TipoMovimiento.auto:
        automaticos++;
        break;
      case TipoMovimiento.ajuste:
        ajustes++;
        break;
    }
  }

  return MovimientoKpis(
    entradasMes: entradas,
    salidasMes: salidas,
    automaticosMes: automaticos,
    ajustesMes: ajustes,
    valorComprasMes: valorCompras,
  );
});
