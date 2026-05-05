// lib/presentation/providers/inventario_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/inventario_service.dart';
import '../../domain/models/inventario_item_model.dart';

// 1. Servicio
final inventarioServiceProvider = Provider<InventarioService>((ref) {
  return InventarioService();
});

// 2. Lista cruda de inventario (AsyncNotifier)
final inventarioProvider =
    AsyncNotifierProvider<InventarioNotifier, List<InventarioItemModel>>(
      InventarioNotifier.new,
    );

class InventarioNotifier extends AsyncNotifier<List<InventarioItemModel>> {
  @override
  Future<List<InventarioItemModel>> build() async {
    return _fetch();
  }

  Future<List<InventarioItemModel>> _fetch() async {
    final service = ref.read(inventarioServiceProvider);
    return service.obtenerInventario();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  /// MOCK — crea un insumo a través del service y lo agrega al state local.
  /// Cuando exista backend, el service hará el INSERT y ya no será mock.
  Future<InventarioItemModel> crearInsumo({
    required String codigo,
    required String nombre,
    required CategoriaInsumo categoria,
    required double stockMinimo,
    required String unidad,
    required double costoUnitario,
    required bool dimensionable,
    String? atributosTecnicosJson,
  }) async {
    final service = ref.read(inventarioServiceProvider);
    final nuevo = await service.crearInsumo(
      codigo: codigo,
      nombre: nombre,
      categoria: categoria,
      stockMinimo: stockMinimo,
      unidad: unidad,
      costoUnitario: costoUnitario,
      dimensionable: dimensionable,
      atributosTecnicosJson: atributosTecnicosJson,
    );
    final actuales = state.value ?? const <InventarioItemModel>[];
    state = AsyncValue.data([...actuales, nuevo]);
    return nuevo;
  }

  /// Genera el siguiente código `INS-NNN` correlativo basado en la lista
  /// actual. Si no hay items, devuelve `INS-001`.
  String generarSiguienteCodigo() {
    final items = state.value ?? const <InventarioItemModel>[];
    if (items.isEmpty) return 'INS-001';
    var maxNumero = 0;
    final regex = RegExp(r'INS-(\d+)');
    for (final item in items) {
      final match = regex.firstMatch(item.codigo);
      if (match != null) {
        final n = int.tryParse(match.group(1)!) ?? 0;
        if (n > maxNumero) maxNumero = n;
      }
    }
    return 'INS-${(maxNumero + 1).toString().padLeft(3, '0')}';
  }

  /// True si ya existe un insumo con ese nombre (case-insensitive, trimmed).
  bool nombreYaExiste(String nombre) {
    final items = state.value ?? const <InventarioItemModel>[];
    final target = nombre.toLowerCase().trim();
    return items.any((item) => item.nombre.toLowerCase().trim() == target);
  }

  /// MOCK — reemplaza el stock de un insumo en la lista en memoria.
  /// Cuando exista backend, esto debe disparar UPDATE en Supabase y
  /// volver a hacer fetch (o aplicar optimistic update + reconciliar).
  void actualizarStock(String idInsumo, double nuevoStock) {
    final current = state.value;
    if (current == null) return;
    final updated = current.map((item) {
      if (item.id != idInsumo) return item;
      return InventarioItemModel(
        id: item.id,
        codigo: item.codigo,
        nombre: item.nombre,
        categoria: item.categoria,
        stockActual: nuevoStock,
        stockMinimo: item.stockMinimo,
        unidad: item.unidad,
        costoUnitario: item.costoUnitario,
      );
    }).toList();
    state = AsyncValue.data(updated);
  }
}

// 3. Estado de filtros
class InventarioFiltros {
  const InventarioFiltros({
    this.query = '',
    this.categoria,
    this.stockBajoOnly = false,
  });

  final String query;
  final CategoriaInsumo? categoria;
  final bool stockBajoOnly;

  InventarioFiltros copyWith({
    String? query,
    CategoriaInsumo? categoria,
    bool? stockBajoOnly,
    bool clearCategoria = false,
  }) {
    return InventarioFiltros(
      query: query ?? this.query,
      categoria: clearCategoria ? null : (categoria ?? this.categoria),
      stockBajoOnly: stockBajoOnly ?? this.stockBajoOnly,
    );
  }

  bool get hasFiltros => query.isNotEmpty || categoria != null || stockBajoOnly;
}

class InventarioFiltrosNotifier extends Notifier<InventarioFiltros> {
  @override
  InventarioFiltros build() => const InventarioFiltros();

  void setQuery(String q) {
    state = state.copyWith(query: q);
  }

  void setCategoria(CategoriaInsumo? cat) {
    state = state.copyWith(categoria: cat, clearCategoria: cat == null);
  }

  void toggleStockBajo() {
    state = state.copyWith(stockBajoOnly: !state.stockBajoOnly);
  }

  void limpiar() {
    state = const InventarioFiltros();
  }
}

final inventarioFiltrosProvider =
    NotifierProvider<InventarioFiltrosNotifier, InventarioFiltros>(
      InventarioFiltrosNotifier.new,
    );

// 4. Lista filtrada (provider derivado)
final inventarioFiltradoProvider = Provider<List<InventarioItemModel>>((ref) {
  final asyncList = ref.watch(inventarioProvider);
  final filtros = ref.watch(inventarioFiltrosProvider);

  final items = asyncList.value ?? const <InventarioItemModel>[];

  return items.where((item) {
    // Filtro categoría
    if (filtros.categoria != null && item.categoria != filtros.categoria) {
      return false;
    }
    // Filtro stock bajo (incluye crítico, bajo y alerta)
    if (filtros.stockBajoOnly) {
      final estado = item.estado;
      if (estado == StockState.ok) return false;
    }
    // Filtro búsqueda
    final q = filtros.query.toLowerCase().trim();
    if (q.isEmpty) return true;
    return item.nombre.toLowerCase().contains(q) ||
        item.codigo.toLowerCase().contains(q);
  }).toList();
});

// 5. KPIs (provider derivado)
class InventarioKpis {
  const InventarioKpis({
    required this.totalInsumos,
    required this.stockBajo,
    required this.stockCritico,
    required this.valorTotalInventario,
  });

  final int totalInsumos;
  final int stockBajo;
  final int stockCritico;
  final double valorTotalInventario;
}

final inventarioKpisProvider = Provider<InventarioKpis>((ref) {
  final asyncList = ref.watch(inventarioProvider);
  final items = asyncList.value ?? const <InventarioItemModel>[];

  var bajo = 0;
  var critico = 0;
  var valor = 0.0;

  for (final item in items) {
    valor += item.valorTotal;
    switch (item.estado) {
      case StockState.critico:
        critico++;
        break;
      case StockState.bajo:
      case StockState.alerta:
        bajo++;
        break;
      case StockState.ok:
        break;
    }
  }

  return InventarioKpis(
    totalInsumos: items.length,
    stockBajo: bajo,
    stockCritico: critico,
    valorTotalInventario: valor,
  );
});
