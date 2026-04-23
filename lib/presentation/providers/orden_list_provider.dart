import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/orden_repository_impl.dart';
import '../../domain/models/orden_model.dart';

class OrdenListNotifier extends AsyncNotifier<List<OrdenModel>> {
  @override
  Future<List<OrdenModel>> build() async {
    // Esto se ejecuta automáticamente al cargar la pantalla
    return _fetchOrdenes();
  }

  Future<List<OrdenModel>> _fetchOrdenes() async {
    final repositorio = OrdenRepositoryImpl();
    return await repositorio.fetchOrdenes();
  }

  // Método por si el usuario jala la pantalla para refrescar
  Future<void> recargarOrdenes() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchOrdenes());
  }
}

final ordenListProvider =
    AsyncNotifierProvider<OrdenListNotifier, List<OrdenModel>>(() {
      return OrdenListNotifier();
    });
