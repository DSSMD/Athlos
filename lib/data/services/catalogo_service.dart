// ============================================================================
// lib/data/services/catalogo_service.dart
// ============================================================================
// Servicio dedicado a catálogos compartidos.
// - tipos de prenda (tabla tipo_prenda)
// - tallas (tabla tallas)
//
// Los providers que consumen este servicio cachean el resultado para
// toda la sesión, evitando llamadas repetidas a la BD.
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/talla_model.dart';
import '../../domain/models/tipo_prenda_model.dart';

class CatalogoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─── TIPOS DE PRENDA ──────────────────────────────────────────────────────

  Future<List<TipoPrendaModel>> obtenerTiposPrenda() async {
    try {
      final response = await _supabase
          .from('tipo_prenda')
          .select('id_tipo_prenda, nombre_prenda, descripcion')
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
}
