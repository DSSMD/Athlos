// lib/presentation/providers/cliente_provider.dart

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/cliente_service.dart';
import '../../domain/models/cliente_model.dart';

// 1. Proveedor del Servicio
final clienteServiceProvider = Provider<ClienteService>((ref) {
  return ClienteService();
});

// 2. Proveedor de la Lista de Clientes (AsyncNotifier)
final clientesProvider = AsyncNotifierProvider<ClientesNotifier, List<ClienteModel>>(() {
  return ClientesNotifier();
});

class ClientesNotifier extends AsyncNotifier<List<ClienteModel>> {
  
  @override
  Future<List<ClienteModel>> build() async {
    return _fetchClientes();
  }

  // Lógica interna para obtener los datos
  Future<List<ClienteModel>> _fetchClientes() async {
    final service = ref.read(clienteServiceProvider);
    return await service.obtenerClientes(); 
  }

  // Refrescar manualmente
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchClientes());
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ACCIÓN: Registrar Cliente
  // ══════════════════════════════════════════════════════════════════════════
  // Retornamos un Future<void> y lanzamos excepción si falla, 
  // para que el Formulario (UI) pueda atrapar el error (ej: CI duplicado).
  Future<void> registrarCliente(ClienteModel cliente) async {
    final service = ref.read(clienteServiceProvider);

    // Usamos guard para intentar crear el cliente y luego refrescar la lista
    state = await AsyncValue.guard(() async {
      await service.registrarCliente(cliente);
      // Tras crear exitosamente, devolvemos la lista fresca de la BD
      return _fetchClientes();
    });

    // Nota: Si 'registrarCliente' del service falla, AsyncValue.guard captura 
    // el error y pone el Provider en estado de AsyncError.
  }
}