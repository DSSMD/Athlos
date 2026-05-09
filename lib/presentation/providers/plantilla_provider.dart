// ============================================================================
// lib/presentation/providers/plantilla_provider.dart
// ============================================================================
// Providers de Riverpod 3 para el módulo Plantillas (DEMO).
// - plantillaServiceProvider: instancia del service
// - plantillaProvider: AsyncNotifier con la lista cruda
// - plantillaFiltrosProvider: estado de filtros (query / tipo / soloActivas)
// - plantillaFiltradoProvider: lista derivada (mock + filtros aplicados)
// - plantillaKpisProvider: KPIs derivados (total, activas, inactivas, tipos)
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/plantilla_service.dart';
import '../../domain/models/plantilla_model.dart';

// ─── SERVICE PROVIDER ───────────────────────────────────────────────────────

final plantillaServiceProvider = Provider<PlantillaService>((ref) {
  return PlantillaService();
});

// ─── LISTA CRUDA (AsyncNotifier) ────────────────────────────────────────────

final plantillaProvider =
    AsyncNotifierProvider<PlantillaNotifier, List<PlantillaModel>>(
      PlantillaNotifier.new,
    );

class PlantillaNotifier extends AsyncNotifier<List<PlantillaModel>> {
  @override
  Future<List<PlantillaModel>> build() async {
    return _fetch();
  }

  Future<List<PlantillaModel>> _fetch() async {
    final service = ref.read(plantillaServiceProvider);
    return service.obtenerPlantillas();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  // ─── TOGGLE ACTIVA / INACTIVA ─────────────────────────────────────────────

  /// Conmuta el flag `activa` de la plantilla y aplica un optimistic update
  /// sobre el state local — no recarga la lista entera. Si el service falla,
  /// rethrowea para que la UI muestre el error y el state queda intacto.
  Future<void> toggleActiva(String id) async {
    final service = ref.read(plantillaServiceProvider);
    try {
      final actualizada = await service.toggleActiva(id);
      final actuales = state.value ?? const <PlantillaModel>[];
      state = AsyncValue.data([
        for (final p in actuales)
          if (p.id == id) actualizada else p,
      ]);
    } catch (_) {
      rethrow;
    }
  }

  // ─── VALIDACIÓN SÍNCRONA DE NOMBRE ÚNICO ──────────────────────────────────

  /// Validación local sobre el state cargado — pensada para el form.
  /// `excludeId` permite ignorar la plantilla en edición. No protege contra
  /// concurrencia: el backend debe tener el constraint final.
  bool nombreYaExiste(String nombre, {String? excludeId}) {
    final items = state.value ?? const <PlantillaModel>[];
    final target = nombre.toLowerCase().trim();
    return items.any(
      (p) => p.id != excludeId && p.nombre.toLowerCase().trim() == target,
    );
  }
}

// ─── FILTROS ────────────────────────────────────────────────────────────────

class PlantillaFiltros {
  const PlantillaFiltros({
    this.query = '',
    this.tipo,
    this.soloActivas = false,
  });

  final String query;
  final TipoPrenda? tipo;
  final bool soloActivas;

  PlantillaFiltros copyWith({
    String? query,
    TipoPrenda? tipo,
    bool? soloActivas,
    bool clearTipo = false,
  }) {
    return PlantillaFiltros(
      query: query ?? this.query,
      tipo: clearTipo ? null : (tipo ?? this.tipo),
      soloActivas: soloActivas ?? this.soloActivas,
    );
  }
}

class PlantillaFiltrosNotifier extends Notifier<PlantillaFiltros> {
  @override
  PlantillaFiltros build() => const PlantillaFiltros();

  void setQuery(String q) {
    state = state.copyWith(query: q);
  }

  void setTipo(TipoPrenda? t) {
    state = state.copyWith(tipo: t, clearTipo: t == null);
  }

  void toggleSoloActivas() {
    state = state.copyWith(soloActivas: !state.soloActivas);
  }

  void limpiar() {
    state = const PlantillaFiltros();
  }
}

final plantillaFiltrosProvider =
    NotifierProvider<PlantillaFiltrosNotifier, PlantillaFiltros>(
      PlantillaFiltrosNotifier.new,
    );

// ─── LISTA FILTRADA (derivado) ──────────────────────────────────────────────

final plantillaFiltradoProvider = Provider<List<PlantillaModel>>((ref) {
  final asyncList = ref.watch(plantillaProvider);
  final filtros = ref.watch(plantillaFiltrosProvider);
  final items = asyncList.value ?? const <PlantillaModel>[];

  return items.where((p) {
    if (filtros.tipo != null && p.tipoPrenda != filtros.tipo) return false;
    if (filtros.soloActivas && !p.activa) return false;
    final q = filtros.query.toLowerCase().trim();
    if (q.isEmpty) return true;
    return p.nombre.toLowerCase().contains(q);
  }).toList();
});

// ─── KPIs (derivado) ────────────────────────────────────────────────────────

class PlantillaKpis {
  const PlantillaKpis({
    required this.total,
    required this.activas,
    required this.inactivas,
    required this.tiposDistintos,
  });

  final int total;
  final int activas;
  final int inactivas;
  final int tiposDistintos;
}

final plantillaKpisProvider = Provider<PlantillaKpis>((ref) {
  final asyncList = ref.watch(plantillaProvider);
  final items = asyncList.value ?? const <PlantillaModel>[];

  final activas = items.where((p) => p.activa).length;
  final tipos = items.map((p) => p.tipoPrenda).toSet().length;

  return PlantillaKpis(
    total: items.length,
    activas: activas,
    inactivas: items.length - activas,
    tiposDistintos: tipos,
  );
});
