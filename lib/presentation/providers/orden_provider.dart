// lib/presentation/providers/orden_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workspace/data/services/orden_service.dart';
import '../../domain/models/orden_model.dart';
import '../../domain/models/auditoria_orden_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Importa también el OrdenDraft si lo necesitas para la creación
import '../components/ordenes/orden_draft.dart';

// Proveedor del servicio
final ordenServiceProvider = Provider<OrdenService>((ref) {
  return OrdenService(Supabase.instance.client);
});

final historialOrdenProvider =
    FutureProvider.family<List<AuditoriaOrdenModel>, String>((
      ref,
      numOrden,
    ) async {
      final service = ref.watch(ordenServiceProvider);
      return await service.obtenerAuditoriaOrden(numOrden);
    });

// Proveedor de la lista de órdenes (AsyncNotifier)
final ordenesProvider =
    AsyncNotifierProvider<OrdenesNotifier, List<OrdenModel>>(() {
      return OrdenesNotifier();
    });

final pagosOrdenProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((
      ref,
      numOrden,
    ) async {
      final response = await Supabase.instance.client
          .from('pago_cliente')
          .select()
          .eq('id_orden', numOrden)
          .order('fecha_pago', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    });

class OrdenesNotifier extends AsyncNotifier<List<OrdenModel>> {
  // Canal de Realtime sobre la tabla `orden`. Vive mientras el provider
  // esté activo; se desuscribe en onDispose.
  RealtimeChannel? _channel;

  @override
  Future<List<OrdenModel>> build() async {
    _subscribeToRealtime();

    ref.onDispose(() {
      _channel?.unsubscribe();
      _channel = null;
    });

    return _fetchOrdenes();
  }

  Future<List<OrdenModel>> _fetchOrdenes() async {
    final service = ref.read(ordenServiceProvider);
    return await service.obtenerOrdenes();
  }

  // Suscripción Realtime a cambios en la tabla `orden`. Ante cualquier
  // INSERT/UPDATE/DELETE re-fetcha la lista completa y setea state
  // directamente con AsyncValue.data — NO con invalidateSelf, porque eso
  // reinicia build() y entra en loop infinito de re-subscripciones.
  void _subscribeToRealtime() {
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id ?? 'anon';

    _channel = supabase
        .channel('ordenes-realtime-$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orden',
          callback: (payload) async {
            try {
              final ordenes = await _fetchOrdenes();
              state = AsyncValue.data(ordenes);
            } catch (e, st) {
              state = AsyncValue.error(e, st);
            }
          },
        )
        .subscribe();
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

  // NUEVO: Agregar ítems a una orden existente y refrescar la lista
  Future<void> agregarItemsAOrden({
    required String numOrden,
    required List<Map<String, dynamic>> nuevosItems,
  }) async {
    try {
      final service = ref.read(ordenServiceProvider);
      await service.agregarItemsAOrden(
        numOrden: numOrden,
        nuevosItems: nuevosItems,
      );
      await refreshOrdenes();
    } catch (e) {
      throw Exception('Error al agregar ítems: $e');
    }
  }
}
