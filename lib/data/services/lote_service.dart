import 'package:supabase_flutter/supabase_flutter.dart';
// Asegúrate de importar el modelo correcto
import 'package:workspace/domain/models/lote_model.dart';

class LoteService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> obtenerHistorialLote(String loteId) async {
    try {
      await Supabase.instance.client
          .from('asignaciones_lote')
          .select('''
            id_asignacion,
            fecha_inicio,
            fecha_fin,
            id_estado_asignacion,
            trabajadores (
              profiles (
                nombre,
                apellido
              )
            )
          ''')
          .eq('id_lote', loteId)
          .order(
            'fecha_inicio',
            ascending: false,
          ); // Ordenamos del más nuevo al más viejo

      // Aquí ya tendrías tu lista para mostrarla en pantalla
    } catch (e) {
      throw Exception('Error al obtener el historial del lote: $e');
    }
  }

  // Función para insertar la nueva asignación
  Future<void> asignarTrabajador(String idLote, String idTrabajador) async {
    try {
      await _supabase.from('asignaciones_lote').insert({
        'id_lote': idLote,
        'id_trabajador': idTrabajador,

        // OJO: Asumo que el estado '1' significa "Asignación Activa" o "En Curso" en tu tabla estado_asignacion.
        // Cámbialo si tu ID de estado activo es otro número.
        'id_estado_asignacion': 1,

        // No mandamos id_asignacion porque se genera solo (gen_random_uuid)
        // No mandamos fecha_inicio porque se pone sola (now)
        // No mandamos fecha_fin porque al iniciar es null
      });
    } catch (e) {
      throw Exception('Error al guardar asignación: $e');
    }
  }

  Future<List<LoteModel>> getLotes() async {
    try {
      // Consulta "a lo bruto" pero usando las relaciones de PostgREST
      // Pedimos los datos de la tabla lote y anidamos las tablas foráneas
      final response = await _supabase
          .from('lote')
          .select('''
        id_lote,
        cantidad_asignada,
        id_estado_lote,
        id_area_actual,
        orden:num_orden (
          num_orden,
          fecha_orden,
          cliente:id_cliente (nom_cliente)
        ),
        plantilla_prenda:id_plantilla (nombre), 
        areas:id_area_actual (nombre_area),
        desglose:id_desglose (
          tallas:id_talla (
            nombre_talla
          )
        )
      ''')
          .order('id_lote', ascending: false);

      // NOTA SOBRE LAS TALLAS:
      // Extraer las tallas directamente desde lote -> desglose -> detalle_talla
      // en una sola consulta de Supabase sin vistas puede ser complejo si la FK no es directa.
      // Si el JSON no trae las tallas aquí, el fromJson le pondrá ['N/A'] temporalmente.

      return (response as List)
          .map((json) => LoteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener los lotes: $e');
    }
  }
}
