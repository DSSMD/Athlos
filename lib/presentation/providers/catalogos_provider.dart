import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/catalogo_service.dart';
import '../../domain/models/tipo_prenda_model.dart';
import '../../domain/models/conjunto_model.dart';
import '../../domain/models/plantilla_model.dart';

// 1. Proveedor del servicio
final catalogoServiceProvider = Provider<CatalogoService>((ref) {
  return CatalogoService();
});

// 2. Proveedor de la lista (FutureProvider porque es de solo lectura)
final tiposPrendaProvider = FutureProvider<List<TipoPrendaModel>>((ref) async {
  final service = ref.read(catalogoServiceProvider);
  return await service.obtenerTiposPrenda();
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
      .select('id_conjunto, nombre, descripcion, precio_conjunto, activo')
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
        'precio_plantilla, version, activo, '
        'tipo_prenda (nombre_prenda)',
      )
      .eq('activo', true)
      .order('nombre');
  return (response as List<dynamic>)
      .map((row) => Plantilla.fromJson(row as Map<String, dynamic>))
      .toList();
});
