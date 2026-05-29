// lib/data/services/produccion_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/trabajo_asignado_model.dart';

class ProduccionService {
  final _supabase = Supabase.instance.client;

  // Traer los trabajos usando la VISTA que creamos en Supabase
  Future<List<TrabajoAsignadoModel>> getMisTrabajos(
    String usuarioAuthId,
  ) async {
    try {
      // Este usuarioAuthId es el que obtienes con currentUser.id
      final response = await _supabase
          .from('vista_trabajos_asignados')
          .select()
          .eq('id_usuario', usuarioAuthId);

      return (response as List)
          .map((json) => TrabajoAsignadoModel.fromJson(json))
          .toList();
    } catch (e) {
      // print('ERROR en getMisTrabajos: $e');
      throw Exception('Error al cargar trabajos: $e');
    }
  }

  // 2. Actualizar el estado de la asignación en la tabla REAL
  Future<void> actualizarEstado(
    String idsAsignaciones,
    String nombreEstado,
  ) async {
    try {
      // 1. Mapeo de seguridad para evitar el error de "0 filas"
      // Si el nombre es 'en proceso', usamos directamente el ID 2 que nos dijiste
      int idEstado;
      String nombreBusqueda = nombreEstado.trim().toLowerCase();

      if (nombreBusqueda == 'en proceso') {
        idEstado = 2;
      } else if (nombreBusqueda == 'terminado') {
        idEstado = 3; // Asumiendo que 3 es terminado, cámbialo si es otro
      } else {
        // Si es otro nombre, buscamos en la tabla
        final res = await _supabase
            .from('estado_asignacion')
            .select('id_estado_asignacion')
            .ilike('nombre_estado', nombreEstado)
            .maybeSingle();

        if (res == null) throw 'El estado "$nombreEstado" no existe en la DB.';
        idEstado = res['id_estado_asignacion'];
      }

      // 2. Convertir el string de IDs en una Lista real para PostgREST
      List<String> listaIds = idsAsignaciones
          .split(',')
          .map((id) => id.trim())
          .where((id) => id.isNotEmpty)
          .toList();

      if (listaIds.isEmpty) return;

      // 3. ACTUALIZACIÓN MASIVA
      // Pasamos la lista directamente al filtro 'in'
      await _supabase
          .from('asignaciones_lote')
          .update({'id_estado_asignacion': idEstado})
          .filter('id_asignacion', 'in', listaIds);

    } catch (e) {
      // print('ERROR REAL: $e');
      throw Exception('No se pudo actualizar: $e');
    }
  }

  // Actualizar el estado de la asignación en la tabla REAL
}
