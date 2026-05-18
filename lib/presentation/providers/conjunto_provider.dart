// ============================================================================
// lib/presentation/providers/conjunto_provider.dart
// ============================================================================
// Providers de Riverpod para el módulo Conjuntos.
//
//   conjuntoServiceProvider  : instancia de ConjuntoService
//   conjuntoProvider         : AsyncNotifierProvider con la lista completa
//   ConjuntoNotifier         : CRUD + optimistic updates
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/conjunto_service.dart';
import '../../domain/models/conjunto_model.dart';

// ─── SERVICE PROVIDER ────────────────────────────────────────────────────────

final conjuntoServiceProvider = Provider<ConjuntoService>((ref) {
  return ConjuntoService();
});

// ─── LISTA COMPLETA (AsyncNotifier) ──────────────────────────────────────────

final conjuntoProvider =
    AsyncNotifierProvider<ConjuntoNotifier, List<ConjuntoModel>>(
      ConjuntoNotifier.new,
    );

class ConjuntoNotifier extends AsyncNotifier<List<ConjuntoModel>> {
  @override
  Future<List<ConjuntoModel>> build() async {
    return _fetch();
  }

  Future<List<ConjuntoModel>> _fetch() {
    return ref.read(conjuntoServiceProvider).obtenerConjuntos();
  }

  // ─── REFRESH ──────────────────────────────────────────────────────────────

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  // ─── CREAR ────────────────────────────────────────────────────────────────

  /// Crea el conjunto en la BD y lo agrega al inicio de la lista local
  /// (optimistic-like: usa el registro real devuelto por el service).
  Future<void> crearConjunto({
    required String nombre,
    required String descripcion,
    required List<ConjuntoPlantillaModel> plantillas,
  }) async {
    final service = ref.read(conjuntoServiceProvider);
    try {
      final nuevo = await service.crearConjunto(
        nombre: nombre,
        descripcion: descripcion,
        plantillas: plantillas,
      );
      final actuales = state.value ?? const [];
      state = AsyncValue.data([nuevo, ...actuales]);
    } catch (_) {
      rethrow;
    }
  }

  // ─── ACTUALIZAR ───────────────────────────────────────────────────────────

  Future<void> actualizarConjunto({
    required String id,
    required String nombre,
    required String descripcion,
    required List<ConjuntoPlantillaModel> plantillas,
  }) async {
    final service = ref.read(conjuntoServiceProvider);
    try {
      final actualizado = await service.actualizarConjunto(
        id: id,
        nombre: nombre,
        descripcion: descripcion,
        plantillas: plantillas,
      );
      final actuales = state.value ?? const [];
      state = AsyncValue.data([
        for (final c in actuales) if (c.id == id) actualizado else c,
      ]);
    } catch (_) {
      rethrow;
    }
  }

  // ─── ELIMINAR ─────────────────────────────────────────────────────────────

  Future<void> eliminarConjunto(String id) async {
    final service = ref.read(conjuntoServiceProvider);
    try {
      await service.eliminarConjunto(id);
      final actuales = state.value ?? const [];
      // Actualizamos el estado local marcándolo como inactivo
      state = AsyncValue.data([
        for (final c in actuales)
          if (c.id == id) c.copyWith(activo: false) else c
      ]);
    } catch (_) {
      rethrow;
    }
  }

  // ─── TOGGLE ACTIVO ────────────────────────────────────────────────────────

  Future<void> toggleActivo(String id) async {
    final service = ref.read(conjuntoServiceProvider);
    try {
      final actualizado = await service.toggleActivo(id);
      final actuales = state.value ?? const [];
      state = AsyncValue.data([
        for (final c in actuales) if (c.id == id) actualizado else c,
      ]);
    } catch (_) {
      rethrow;
    }
  }
}
