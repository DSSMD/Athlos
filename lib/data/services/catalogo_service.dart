// ============================================================================
// lib/data/services/catalogo_service.dart
// ============================================================================
// Servicio dedicado a catálogos compartidos.
// - tipos de prenda (tabla tipo_prenda)
// - tallas         (tabla tallas)
// - insumos        (tabla insumo, join a unidad_medida)
//
// Los providers que consumen este servicio cachean el resultado para
// toda la sesión, evitando llamadas repetidas a la BD.
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/insumo_model.dart';
import '../../domain/models/talla_model.dart';
import '../../domain/models/tipo_prenda_model.dart';

class CatalogoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── TIPOS DE PRENDA ──────────────────────────────────────────────────────

  Future<List<TipoPrendaModel>> obtenerTiposPrenda() async {
    try {
      final response = await _supabase
          .from('tipo_prenda')
          .select('id_tipo_prenda, nombre_prenda, descripcion, categoria_prenda')
          .order('categoria_prenda')
          .order('nombre_prenda');
      return (response as List)
          .map((j) => TipoPrendaModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar tipos de prenda: $e');
    }
  }

  // ─── TALLAS ───────────────────────────────────────────────────────────────

  Future<List<TallaModel>> obtenerTallas() async {
    try {
      final response = await _supabase
          .from('tallas')
          .select('id_talla, nombre_talla, descripcion')
          .order('id_talla');
      return (response as List)
          .map((j) => TallaModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar tallas: $e');
    }
  }

  // ─── INSUMOS ──────────────────────────────────────────────────────────────

  // DECISIÓN: filtrar `soloActivos=true` por default.
  // RAZÓN: el trigger SQL de receta_material bloquea inserts con insumos
  // inactivos. No tiene sentido ofrecerlos en el dropdown del Paso 3.
  // CAMBIAR: pasar `soloActivos: false` desde admin si quieren ver todos.
  Future<List<InsumoModel>> obtenerInsumos({bool soloActivos = true}) async {
    try {
      final base = _supabase
          .from('insumo')
          .select('id_insumo, nombre, activo, unidad_medida(abreviatura)');
      final filtered = soloActivos ? base.eq('activo', true) : base;
      final response = await filtered.order('nombre');
      return (response as List)
          .map((j) => InsumoModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar insumos: $e');
    }
  }
}
