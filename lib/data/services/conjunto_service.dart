// ============================================================================
// lib/data/services/conjunto_service.dart
// ============================================================================
// Servicio del módulo Conjuntos — integración directa con Supabase.
//
// Tablas que toca:
//   - conjunto           (tabla principal)
//   - conjunto_plantilla (tabla intermedia, FK CASCADE al eliminar conjunto)
//
// Estrategia de escritura:
//   - crearConjunto    : INSERT en conjunto → INSERT lote en conjunto_plantilla
//   - actualizarConjunto: UPDATE conjunto → DELETE+INSERT en conjunto_plantilla
//     (replace-all: más simple y sin riesgo de duplicados por unique constraint)
//   - eliminarConjunto : DELETE conjunto (CASCADE borra conjunto_plantilla)
//   - toggleActivo     : UPDATE activo en conjunto
//
// NOTA: las operaciones múltiples no son transaccionales a nivel cliente.
// conjunto con sus plantillas en una sola transacción atómica.
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/conjunto_model.dart';

class ConjuntoService {
  final SupabaseClient _client = Supabase.instance.client;

  // ─── SELECT COMPLETO (query reutilizable) ─────────────────────────────────

  /// Columnas a seleccionar en todas las queries de lectura.
  /// Hace join: conjunto → conjunto_plantilla → plantilla_prenda.
  static const String _selectQuery = '''
    id_conjunto,
    nombre,
    descripcion,
    activo,
    created_at,
    precio_conjunto,
    conjunto_plantilla (
      id_cp,
      id_conjunto,
      id_plantilla,
      cantidad_por_conjunto,
      plantilla_prenda (
        nombre,
        precio_plantilla
      )
    )
  ''';

  // ─── OBTENER CONJUNTOS ────────────────────────────────────────────────────

  /// Retorna todos los conjuntos con sus plantillas anidadas.
  Future<List<ConjuntoModel>> obtenerConjuntos() async {
    try {
      final response = await _client
          .from('conjunto')
          .select(_selectQuery)
          .order('created_at', ascending: false);

      return (response as List)
          .map((j) => ConjuntoModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar conjuntos: $e');
    }
  }

  // ─── CREAR CONJUNTO ───────────────────────────────────────────────────────

  /// Inserta el conjunto y luego inserta las filas en conjunto_plantilla.
  /// El precio_conjunto se calcula desde los ítems y se persiste en BD.
  Future<ConjuntoModel> crearConjunto({
    required String nombre,
    required String descripcion,
    required List<ConjuntoPlantillaModel> plantillas,
  }) async {
    try {
      // 1) Calcular el precio total antes de insertar
      final precioTotal = plantillas.fold<double>(
        0.0,
        (sum, p) => sum + p.subtotal,
      );

      // 2) Insertar el conjunto principal
      final insertResponse = await _client
          .from('conjunto')
          .insert({
            'nombre': nombre.trim(),
            'descripcion': descripcion.trim(),
            'activo': true,
            'precio_conjunto': precioTotal,
          })
          .select('id_conjunto')
          .single();

      final idConjunto = insertResponse['id_conjunto'].toString();

      // 3) Insertar las filas de conjunto_plantilla
      if (plantillas.isNotEmpty) {
        final filas = plantillas
            .map((p) => p.toInsertJson(idConjunto))
            .toList();
        await _client.from('conjunto_plantilla').insert(filas);
      }

      // 4) Re-leer para obtener el registro con el join completo
      return _fetchById(idConjunto);
    } catch (e) {
      throw _traducirError(e);
    }
  }

  // ─── ACTUALIZAR CONJUNTO ──────────────────────────────────────────────────

  /// Actualiza nombre/descripción/precio y reemplaza todas las plantillas
  /// (DELETE + INSERT lote).
  Future<ConjuntoModel> actualizarConjunto({
    required String id,
    required String nombre,
    required String descripcion,
    required List<ConjuntoPlantillaModel> plantillas,
  }) async {
    try {
      // 1) Calcular nuevo precio
      final precioTotal = plantillas.fold<double>(
        0.0,
        (sum, p) => sum + p.subtotal,
      );

      // 2) Actualizar el conjunto principal
      await _client.from('conjunto').update({
        'nombre': nombre.trim(),
        'descripcion': descripcion.trim(),
        'precio_conjunto': precioTotal,
      }).eq('id_conjunto', id);

      // 3) Reemplazar plantillas: borrar todas y reinsertar
      await _client
          .from('conjunto_plantilla')
          .delete()
          .eq('id_conjunto', id);

      if (plantillas.isNotEmpty) {
        final filas = plantillas.map((p) => p.toInsertJson(id)).toList();
        await _client.from('conjunto_plantilla').insert(filas);
      }

      // 4) Re-leer con join completo
      return _fetchById(id);
    } catch (e) {
      throw _traducirError(e);
    }
  }

  // ─── ELIMINAR CONJUNTO ────────────────────────────────────────────────────

  /// Soft Delete: Marca el conjunto como inactivo en lugar de borrarlo físicamente
  /// para no romper el historial de órdenes/pedidos.
  Future<void> eliminarConjunto(String id) async {
    try {
      await _client.from('conjunto').update({'activo': false}).eq('id_conjunto', id);
    } catch (e) {
      throw Exception('Error al dar de baja el conjunto: $e');
    }
  }

  // ─── TOGGLE ACTIVO / INACTIVO ─────────────────────────────────────────────

  Future<ConjuntoModel> toggleActivo(String id) async {
    try {
      final current = await _client
          .from('conjunto')
          .select('activo')
          .eq('id_conjunto', id)
          .single();

      final estadoActual = (current['activo'] as bool?) ?? true;

      await _client
          .from('conjunto')
          .update({'activo': !estadoActual})
          .eq('id_conjunto', id);

      return _fetchById(id);
    } catch (e) {
      throw Exception('Error al cambiar estado del conjunto: $e');
    }
  }

  // ─── HELPERS PRIVADOS ─────────────────────────────────────────────────────

  /// Lee un conjunto con join completo por id. Se usa después de
  /// crear/actualizar para devolver el estado real de la BD.
  Future<ConjuntoModel> _fetchById(String id) async {
    final response = await _client
        .from('conjunto')
        .select(_selectQuery)
        .eq('id_conjunto', id)
        .single();

    return ConjuntoModel.fromJson(response);
  }

  /// Traduce errores de Supabase a mensajes amigables.
  Exception _traducirError(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('unique') && msg.contains('plantilla')) {
      return Exception('Esa plantilla ya está en el conjunto.');
    }
    if (msg.contains('fk_cp_plantilla') || msg.contains('restrict')) {
      return Exception(
        'No se puede eliminar: la plantilla está en uso.',
      );
    }
    return Exception('Error al guardar conjunto: $error');
  }
}
