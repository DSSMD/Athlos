// ============================================================================
// lib/presentation/providers/catalogos_provider.dart
// ============================================================================
// Providers de catálogos compartidos (tipos de prenda, tallas).
//
// DECISIÓN: FutureProvider SIN autoDispose.
// RAZÓN: catálogos se cachean para toda la sesión, evita llamadas redundantes
// cada vez que se abre un dropdown.
// CAMBIAR: si necesitan refresh manual (admin agregó un tipo y quiere verlo
// sin recargar), usar ref.invalidate(tiposPrendaProvider) desde la UI.
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/catalogo_service.dart';
import '../../domain/models/insumo_model.dart';
import '../../domain/models/talla_model.dart';
import '../../domain/models/tipo_prenda_model.dart';

final catalogoServiceProvider = Provider<CatalogoService>((ref) {
  return CatalogoService();
});

final tiposPrendaProvider = FutureProvider<List<TipoPrendaModel>>((ref) async {
  final service = ref.read(catalogoServiceProvider);
  return service.obtenerTiposPrenda();
});

final tallasProvider = FutureProvider<List<TallaModel>>((ref) async {
  final service = ref.read(catalogoServiceProvider);
  return service.obtenerTallas();
});

/// Solo insumos activos (filtrados por la BD). El trigger del backend
/// bloquea inserts en `receta_material` con insumos inactivos, así que
/// no tiene sentido mostrarlos en el dropdown del Paso 3.
final insumosProvider = FutureProvider<List<InsumoModel>>((ref) async {
  final service = ref.read(catalogoServiceProvider);
  return service.obtenerInsumos(soloActivos: true);
});

/// Lista de categorías únicas ordenadas alfabéticamente, derivada del
/// catálogo `tiposPrendaProvider` ya cargado — sin query extra.
///
/// Devuelve `AsyncValue<List<String>>` sincronizado con `tiposPrendaProvider`.
/// Si el catálogo aún carga o falla, este provider refleja el mismo estado.
/// Orden: alfabético (Accesorio, Exterior, Inferior, Superior).
///
/// Uso en el formulario de Plantillas (Paso 1): el usuario elige primero
/// la categoría, y luego el tipo de prenda filtrado por esa categoría.
final categoriasPrendaProvider = Provider<AsyncValue<List<String>>>((ref) {
  final tiposAsync = ref.watch(tiposPrendaProvider);
  return tiposAsync.whenData((tipos) {
    final cats = tipos.map((t) => t.categoria).toSet().toList()..sort();
    return cats;
  });
});
