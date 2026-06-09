// lib/data/services/cliente_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/cliente_model.dart';

class ClienteService {
  final _supabase = Supabase.instance.client;

  // ══════════════════════════════════════════════════════════════════════════
  // CREACIÓN
  // ══════════════════════════════════════════════════════════════════════════
  Future<ClienteModel> registrarCliente(ClienteModel cliente) async {
    try {
      final response = await _supabase
          .from('cliente')
          .insert(cliente.toJson())
          .select()
          .single();

      return ClienteModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // unique_violation
        throw Exception('Ya existe un cliente registrado con este CI/NIT.');
      }
      throw Exception('Error de base de datos: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al registrar el cliente: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LECTURA
  // ══════════════════════════════════════════════════════════════════════════
  Future<List<ClienteModel>> obtenerClientes({bool soloActivos = true}) async {
    try {
      // 1. Modificamos el select para que también traiga las órdenes y los pagos
      var query = _supabase.from('cliente').select('''
        *,
        orden (
          fecha_orden,
          costo_total,
          pago_cliente ( monto )
        )
      ''');

      // 2. Mantenemos tu filtro original intacto
      if (soloActivos) {
        query = query.eq('activo', true);
      }

      final response = await query.order('created_at', ascending: false);

      // 3. Hacemos el cálculo matemático antes de convertir a ClienteModel
      return (response as List<dynamic>).map((json) {
        final ordenes = json['orden'] as List<dynamic>? ?? [];

        int totalOrdenes = ordenes.length;
        double totalComprado = 0;
        double deudaTotal = 0;
        DateTime? ultimoPedido;

        for (var o in ordenes) {
          final costo = (o['costo_total'] ?? 0).toDouble();
          totalComprado += costo;

          final pagos = o['pago_cliente'] as List<dynamic>? ?? [];
          double pagado = pagos.fold(
            0.0,
            (sum, p) => sum + (p['monto'] ?? 0).toDouble(),
          );

          deudaTotal += (costo - pagado);

          if (o['fecha_orden'] != null) {
            final fechaOrd = DateTime.parse(o['fecha_orden']);
            if (ultimoPedido == null || fechaOrd.isAfter(ultimoPedido)) {
              ultimoPedido = fechaOrd;
            }
          }
        }

        // Inyectamos los cálculos al diccionario
        json['total_ordenes'] = totalOrdenes;
        json['total_comprado'] = totalComprado;
        json['deuda_total'] = deudaTotal;
        json['ultimo_pedido'] = ultimoPedido?.toIso8601String();

        return ClienteModel.fromJson(json as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      throw Exception('Error al obtener clientes: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ACTUALIZACIÓN
  // ══════════════════════════════════════════════════════════════════════════
  Future<ClienteModel> actualizarCliente(ClienteModel cliente) async {
    if (cliente.idCliente == null) {
      throw Exception('No se puede actualizar un cliente sin su ID.');
    }

    try {
      final response = await _supabase
          .from('cliente')
          .update(cliente.toJson())
          .eq('id_cliente', cliente.idCliente!)
          .select()
          .single();

      return ClienteModel.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        // unique_violation
        throw Exception('El CI/NIT ingresado ya pertenece a otro cliente.');
      }
      throw Exception('Error de base de datos: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al actualizar el cliente: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BORRADO LÓGICO (SOFT DELETE) / REACTIVACIÓN
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> cambiarEstadoCliente(String idCliente, bool activo) async {
    try {
      await _supabase
          .from('cliente')
          .update({'activo': activo})
          .eq('id_cliente', idCliente);
    } catch (e) {
      final accion = activo ? 'reactivar' : 'eliminar';
      throw Exception('Error al $accion el cliente: $e');
    }
  }
}
