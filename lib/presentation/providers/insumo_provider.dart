// lib/presentation/providers/inventario_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/inventario_service.dart';
import '../../domain/models/inventario_model.dart';

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

  Future<void> cambiarEstadoInsumo(String id, bool nuevoEstado) async {
    final service = ref.read(inventarioServiceProvider);

    // 1. Guardamos en la base de datos
    await service.actualizarEstadoActivo(id, nuevoEstado);

    // 2. Refrescamos la lista local para que el Switch se mueva visualmente
    // Esto obliga a Flutter a volver a descargar los datos reales
    ref.invalidateSelf();
    
    // 3. Invalidamos el catálogo para que el dropdown de Plantillas se actualice
    ref.invalidate(inventarioProvider);
  }

  /// MOCK — crea un insumo a través del service y lo agrega al state local.
  /// Cuando exista backend, el service hará el INSERT y ya no será mock.
  Future<InventarioItemModel> crearInsumo({
    required String nombre,
    required int idCategoria,
    required double stockMinimo,
    required int idUnidad,
    required bool dimensionable,
    String? atributosTecnicosJson,
  }) async {
    final service = ref.read(inventarioServiceProvider);
    final nuevo = await service.crearInsumo(
      nombre: nombre,
      idCategoria: idCategoria,
      stockMinimo: stockMinimo,
      idUnidad: idUnidad,
      dimensionable: dimensionable,
      atributosTecnicosJson: atributosTecnicosJson,
    );
    final actuales = state.value ?? const <InventarioItemModel>[];
    state = AsyncValue.data([...actuales, nuevo]);
    
    // Invalidamos el catálogo para que el nuevo insumo aparezca en Plantillas
    ref.invalidate(inventarioProvider);
    
    return nuevo;
  }

  /// True si ya existe un insumo con ese nombre (case-insensitive, trimmed).
  bool nombreYaExiste(String nombre) {
    final items = state.value ?? const <InventarioItemModel>[];
    final target = nombre.toLowerCase().trim();
    return items.any((item) => item.nombre.toLowerCase().trim() == target);
  }

  /// Persiste el nuevo stock en Supabase y refresca la lista local.
  Future<void> actualizarStock(String idInsumo, double nuevoStock) async {
    final service = ref.read(inventarioServiceProvider);
    await service.actualizarStockInsumo(idInsumo, nuevoStock);
    // Invalidar fuerza un re-fetch real desde BD para que la UI quede sincronizada.
    ref.invalidateSelf();
  }
}

enum InventarioOrden {
  recientes('Recientes', 'recientes'),
  alfabetico('A-Z', 'alfabetico'),
  stockMenor('Menor stock', 'stock_asc'),
  stockMayor('Mayor stock', 'stock_desc');

  const InventarioOrden(this.label, this.value);
  final String label;
  final String value;
}

// 3. Estado de filtros
class InventarioFiltros {
  const InventarioFiltros({
    this.query = '',
    this.nombreCategoriaFiltro,
    this.stockBajoOnly = false,
    this.orden = InventarioOrden.recientes,
  });

  final String query;
  final String? nombreCategoriaFiltro;
  final bool stockBajoOnly;
  final InventarioOrden orden;

  InventarioFiltros copyWith({
    String? query,
    String? nombreCategoriaFiltro,
    bool? stockBajoOnly,
    InventarioOrden? orden,
    bool clearCategoria = false,
  }) {
    return InventarioFiltros(
      query: query ?? this.query,
      nombreCategoriaFiltro: clearCategoria ? null : (nombreCategoriaFiltro ?? this.nombreCategoriaFiltro),
      stockBajoOnly: stockBajoOnly ?? this.stockBajoOnly,
      orden: orden ?? this.orden,
    );
  }

  bool get hasFiltros => query.isNotEmpty || nombreCategoriaFiltro != null || stockBajoOnly || orden != InventarioOrden.recientes;
}

class InventarioFiltrosNotifier extends Notifier<InventarioFiltros> {
  @override
  InventarioFiltros build() => const InventarioFiltros();

  void setQuery(String q) {
    state = state.copyWith(query: q);
  }

  void setCategoria(String? nombreCategoria) {
    state = state.copyWith(nombreCategoriaFiltro: nombreCategoria, clearCategoria: nombreCategoria == null);
  }

  void toggleStockBajo() {
    state = state.copyWith(stockBajoOnly: !state.stockBajoOnly);
  }

  void setOrden(InventarioOrden orden) {
    state = state.copyWith(orden: orden);
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
    if (filtros.nombreCategoriaFiltro != null && item.nombreCategoria != filtros.nombreCategoriaFiltro) {
      return false;
    }
    // Filtro stock bajo (incluye crítico, bajo y alerta)
    if (filtros.stockBajoOnly) {
      final estado = item.estado;
      if (estado == StockState.ok) return false;
    }
    // Filtro búsqueda: nombre + código + categoría (snake_case del enum).
    // `categoria.name` da por ejemplo "telas", "hilos" — coincide con cómo
    // el usuario tipea en el buscador (case-insensitive vía .toLowerCase).
    final q = filtros.query.toLowerCase().trim();
    if (q.isEmpty) return true;
    return item.nombre.toLowerCase().contains(q) ||
        item.codigo.toLowerCase().contains(q) ||
        item.nombreCategoria.toLowerCase().contains(q);
  }).toList()
  ..sort((a, b) {
    switch (filtros.orden) {
      case InventarioOrden.alfabetico:
        return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
      case InventarioOrden.stockMenor:
        return a.stockActual.compareTo(b.stockActual);
      case InventarioOrden.stockMayor:
        return b.stockActual.compareTo(a.stockActual);
      case InventarioOrden.recientes:
      // Por ahora, usamos el ID para simular más recientes (los UUID nuevos suelen ser más grandes lexicográficamente, aunque no siempre, idealmente usaríamos un campo creado_en).
        return b.id.compareTo(a.id); 
    }
  });
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


final categoriasProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.read(inventarioServiceProvider).obtenerCategoriasDropdown();
});
