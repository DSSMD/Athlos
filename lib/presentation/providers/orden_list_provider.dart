import 'package:flutter_riverpod/flutter_riverpod.dart';
// TODO(SCRUM-75): re-importar cuando se destrabe _fetchOrdenes
// import '../../data/repositories/orden_repository_impl.dart';
import '../../domain/models/orden_model.dart';

class OrdenListNotifier extends AsyncNotifier<List<OrdenModel>> {
  @override
  Future<List<OrdenModel>> build() async {
    // Esto se ejecuta automáticamente al cargar la pantalla
    return _fetchOrdenes();
  }

  Future<List<OrdenModel>> _fetchOrdenes() async {
    // TODO(SCRUM-75): destrabar cuando Mel agregue el método de lectura en el
    // repositorio. Hoy OrdenRepositoryImpl solo expone guardarOrdenMultimodal
    // (lógica antigua que Den marcó para refactor). Para que la pantalla
    // de Órdenes (SCRUM-72) compile mientras tanto, devolvemos lista vacía.
    // Cuando esté disponible el método real (ej. obtenerOrdenes), reemplazar
    // el cuerpo de este método por:
    //   final repositorio = OrdenRepositoryImpl();
    //   return await repositorio.obtenerOrdenes();
    return <OrdenModel>[];
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
