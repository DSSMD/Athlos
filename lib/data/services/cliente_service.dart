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
      var query = _supabase.from('cliente').select();

      // Si soloActivos es true, filtramos los eliminados lógicamente
      if (soloActivos) {
        query = query.eq('activo', true);
      }

      final response = await query.order('created_at', ascending: false);

      return (response as List)
          .map((json) => ClienteModel.fromJson(json))
          .toList();
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
