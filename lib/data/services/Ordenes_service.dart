import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/orden_model.dart'; // Tu modelo

class OrdenService {
  final _supabase = Supabase.instance.client;

  // ══════════════════════════════════════════════════════════════════════════
  // LECTURA (Lo que ya hicimos)
  // ══════════════════════════════════════════════════════════════════════════
  Future<List<OrdenModel>> fetchOrdenes() async {
    try {
      final response = await _supabase
          .from('ordenes')
          .select(
            'id, cliente_id, ficha_tecnica_id, cantidad_total, fecha_entrega, estado, notas',
          )
          .order('fecha_entrega', ascending: true);

      return (response as List<dynamic>)
          .map((json) => OrdenModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener las órdenes: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CREACIÓN (Para conectar con tu formulario de la imagen)
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> crearOrden({
    required int clienteId,
    required int fichaTecnicaId,
    required int cantidadTotal,
    required DateTime fechaEntrega,
    String? notas,
  }) async {
    try {
      // Inserción directa en la tabla de Supabase
      await _supabase.from('ordenes').insert({
        'cliente_id': clienteId,
        'ficha_tecnica_id': fichaTecnicaId,
        'cantidad_total': cantidadTotal,
        // Supabase necesita la fecha en formato ISO 8601 (String)
        'fecha_entrega': fechaEntrega.toIso8601String(),
        'notas': notas,
        'estado': 'Pendiente', // Estado inicial por defecto
      });
    } catch (e) {
      throw Exception('Error al crear la orden: $e');
    }
  }
}
