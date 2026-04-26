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
  /// Registra un cliente. Si falla, conserva el estado actual de la lista
  /// (no la rompe) y relanza la excepción para que el formulario la muestre.
  Future<void> registrarCliente(ClienteModel cliente) async {
    final service = ref.read(clienteServiceProvider);
    try {
      await service.registrarCliente(cliente);
      // Si el guardado fue exitoso, refrescamos la lista
      state = await AsyncValue.guard(() => _fetchClientes());
    } catch (e) {
      // Si falla, NO tocamos el state (la lista queda intacta)
      // y relanzamos para que el form muestre el error.
      rethrow;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ACCIÓN: Actualizar Cliente
  // ══════════════════════════════════════════════════════════════════════════
  /// Actualiza un cliente. Si falla, conserva el estado actual de la lista
  /// (no la rompe) y relanza la excepción para que el formulario la muestre.
  Future<void> actualizarCliente(ClienteModel cliente) async {
    final service = ref.read(clienteServiceProvider);
    try {
      await service.actualizarCliente(cliente);
      state = await AsyncValue.guard(() => _fetchClientes());
    } catch (e) {
      rethrow;
    }
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
