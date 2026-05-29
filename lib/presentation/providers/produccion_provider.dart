// lib/presentation/providers/produccion_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/produccion_service.dart';
import '../../domain/models/trabajo_asignado_model.dart';

// Proveedor del servicio
final produccionServiceProvider = Provider<ProduccionService>((ref) {
  // Asumiendo que tu ProduccionService se instancia así
  return ProduccionService();
});

// Proveedor de la lista de trabajos (AsyncNotifier)
final misTrabajosProvider =
    AsyncNotifierProvider<MisTrabajosNotifier, List<TrabajoAsignadoModel>>(() {
      return MisTrabajosNotifier();
    });

class MisTrabajosNotifier extends AsyncNotifier<List<TrabajoAsignadoModel>> {
  @override
  Future<List<TrabajoAsignadoModel>> build() async {
    return _fetchMisTrabajos();
  }

  Future<List<TrabajoAsignadoModel>> _fetchMisTrabajos() async {
    // AQUÍ: Obtenemos el ID de la cuenta con la que iniciaste sesión
    final userId = Supabase.instance.client.auth.currentUser?.id;

    if (userId == null) return [];

    final service = ref.read(produccionServiceProvider);

    // AQUÍ: Le mandamos ese ID al Service
    return await service.getMisTrabajos(userId);
  }

  // Método para recargar la lista después de actualizar un estado
  Future<void> refreshMisTrabajos() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchMisTrabajos());
  }

  // NUEVO: Método para cambiar el estado y recargar la lista
  Future<void> cambiarEstado(String idAsignacion, String nuevoEstado) async {
    try {
      final service = ref.read(produccionServiceProvider);

      // 1. Guardamos el nuevo estado en Supabase
      await service.actualizarEstado(idAsignacion, nuevoEstado);

      // 2. Si fue exitoso, refrescamos la lista para que la tabla se actualice
      await refreshMisTrabajos();
    } catch (e) {
      // Lanzamos el error para que la interfaz (UI) pueda mostrar un SnackBar
      throw Exception('Error al actualizar estado: $e');
    }
  }
}
