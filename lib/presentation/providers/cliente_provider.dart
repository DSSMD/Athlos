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
final clientesProvider =
    AsyncNotifierProvider<ClientesNotifier, List<ClienteModel>>(() {
      return ClientesNotifier();
    });

class ClientesNotifier extends AsyncNotifier<List<ClienteModel>> {
  @override
  Future<List<ClienteModel>> build() async {
    return _fetchClientes();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MÉTODO PRIVADO PARA OBTENER CLIENTES (con opción de filtrar solo activos)
  // ══════════════════════════════════════════════════════════════════════════
  Future<List<ClienteModel>> _fetchClientes() async {
    final service = ref.read(clienteServiceProvider);
    // Traemos todos (activos e inactivos) para que el filter chip
    // "Inactivos" funcione. El filtrado por estado se hace en la UI.
    return await service.obtenerClientes(soloActivos: false);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // MÉTODO PARA REFRESCAR LA LISTA (puede ser llamado tras acciones de CRUD)
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchClientes());
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ACCIÓN: Registrar Cliente
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> registrarCliente(ClienteModel cliente) async {
    final service = ref.read(clienteServiceProvider);

    state = await AsyncValue.guard(() async {
      await service.registrarCliente(cliente);
      return _fetchClientes(); // Refrescamos la lista tras el éxito
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ACCIÓN: Actualizar Cliente
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> actualizarCliente(ClienteModel cliente) async {
    final service = ref.read(clienteServiceProvider);

    state = await AsyncValue.guard(() async {
      await service.actualizarCliente(cliente);
      return _fetchClientes();
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ACCIÓN: Eliminar (Soft Delete) / Reactivar
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> cambiarEstado(String idCliente, bool activo) async {
    final service = ref.read(clienteServiceProvider);

    state = await AsyncValue.guard(() async {
      await service.cambiarEstadoCliente(idCliente, activo);
      return _fetchClientes();
    });
  }
}
