// lib/presentation/providers/orden_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workspace/data/services/orden_service.dart';
import '../../domain/models/orden_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Importa también el OrdenDraft si lo necesitas para la creación
import '../components/ordenes/orden_draft.dart';

// Proveedor del servicio
final ordenServiceProvider = Provider<OrdenService>((ref) {
  return OrdenService(Supabase.instance.client);
});

// Proveedor de la lista de órdenes (AsyncNotifier)
final ordenesProvider =
    AsyncNotifierProvider<OrdenesNotifier, List<OrdenModel>>(() {
      return OrdenesNotifier();
    });

class OrdenesNotifier extends AsyncNotifier<List<OrdenModel>> {
  @override
  Future<List<OrdenModel>> build() async {
    return _fetchOrdenes();
  }

  Future<List<OrdenModel>> _fetchOrdenes() async {
    final service = ref.read(ordenServiceProvider);
    return await service.obtenerOrdenes();
  }

  // Método para recargar la lista después de crear una nueva orden
  Future<void> refreshOrdenes() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchOrdenes());
  }

  // NUEVO: Método para crear la orden y recargar la lista
  Future<void> crearNuevaOrden(OrdenDraft draft) async {
    try {
      final service = ref.read(ordenServiceProvider);
      // 1. Guardamos la orden en Supabase (esto ya incluye el cálculo de costos internamente)
      await service.crearOrdenDesdeDraft(draft);

      // 2. Si fue exitoso, refrescamos la lista para que la tabla se actualice
      await refreshOrdenes();
    } catch (e) {
      // Lanzamos el error para que la interfaz (UI) pueda mostrar un SnackBar
      throw Exception('Error al crear orden: $e');
    }
  }
}
