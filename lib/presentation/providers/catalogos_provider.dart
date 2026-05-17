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
import '../../domain/models/conjunto_model.dart';
import '../../domain/models/plantilla_model.dart';

final catalogoServiceProvider = Provider<CatalogoService>((ref) {
  return CatalogoService();
});

final tiposPrendaProvider = FutureProvider<List<TipoPrendaModel>>((ref) async {
  final service = ref.read(catalogoServiceProvider);
  return service.obtenerTiposPrenda();
});

// (Añade esto al final de tu catalogos_provider.dart)
// Nota: Puedes usar un modelo genérico o Map<String, dynamic> como hicimos al principio si quieres ir rápido.
final tallasProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('tallas')
      .select('id_talla, nombre_talla')
      .order(
        'id_talla',
      ); // Ordenamos por ID para que salga S, M, L, XL en orden
  return List<Map<String, dynamic>>.from(response);
});

// Lista de conjuntos activos del catálogo (para el dropdown del form de orden).
// Consulta directa a Supabase usando el modelo tipado Conjunto.
final conjuntosProvider = FutureProvider<List<Conjunto>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('conjunto')
      .select('id_conjunto, nombre, descripcion, activo')
      .eq('activo', true)
      .order('nombre');
  return (response as List<dynamic>)
      .map((row) => Conjunto.fromJson(row as Map<String, dynamic>))
      .toList();
});

// Lista de plantillas activas del catálogo (para el dropdown del form de orden).
// Incluye join con tipo_prenda para poblar nombreTipoPrenda en el modelo.
final plantillasProvider = FutureProvider<List<Plantilla>>((ref) async {
  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('plantilla_prenda')
      .select(
        'id_plantilla, id_tipo_prenda, nombre, especificaciones, '
        'version, activo, '
        'tipo_prenda (nombre_prenda)',
      )
      .eq('activo', true)
      .order('nombre');
  return (response as List<dynamic>)
      .map((row) => Plantilla.fromJson(row as Map<String, dynamic>))
      .toList();
});
