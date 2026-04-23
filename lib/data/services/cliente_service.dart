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
      // .insert() agrega, .select().single() nos devuelve el objeto ya creado
      // con su id_cliente y created_at generados por la base de datos.
      final response = await _supabase
          .from('cliente')
          .insert(cliente.toJson())
          .select()
          .single();

      return ClienteModel.fromJson(response);
    } on PostgrestException catch (e) {
      // Manejo específico del UNIQUE de ci_cliente
      if (e.code == '23505') {
        // 23505 es el código SQL para unique_violation
        throw Exception('Ya existe un cliente registrado con este CI.');
      }
      throw Exception('Error de base de datos: ${e.message}');
    } catch (e) {
      throw Exception('Error inesperado al registrar el cliente: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LECTURA
  // ══════════════════════════════════════════════════════════════════════════
  Future<List<ClienteModel>> obtenerClientes() async {
    try {
      final response = await _supabase
          .from('cliente')
          .select()
          .order('created_at', ascending: false); // Ordenados por más recientes

      return (response as List)
          .map((json) => ClienteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener clientes: $e');
    }
  }
}
