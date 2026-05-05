// MOCK — eliminar / reemplazar con Supabase cuando exista tabla
// `movimiento_insumo`. La lista vive en memoria del proceso, se pierde al
// reiniciar la app.

import '../../domain/models/movimiento_model.dart';

class MovimientoService {
  MovimientoService();

  static const bool _useMockData = true;

  // Lista mockeada en memoria.
  final List<MovimientoModel> _mock = [];

  Future<List<MovimientoModel>> obtenerMovimientos() async {
    if (_useMockData) {
      return List.unmodifiable(_mock);
    }
    // TODO: query a Supabase tabla `movimiento_insumo`.
    throw UnimplementedError();
  }

  Future<List<MovimientoModel>> obtenerMovimientosPorInsumo(
    String idInsumo,
  ) async {
    if (_useMockData) {
      return _mock.where((m) => m.idInsumo == idInsumo).toList();
    }
    // TODO: query filtrado por id_insumo en Supabase.
    throw UnimplementedError();
  }

  Future<MovimientoModel> crearMovimiento({
    required String idInsumo,
    required TipoMovimiento tipo,
    required double cantidad,
    required String motivo,
    required String usuario,
  }) async {
    if (_useMockData) {
      final m = MovimientoModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        idInsumo: idInsumo,
        tipo: tipo,
        cantidad: cantidad,
        motivo: motivo,
        fecha: DateTime.now(),
        usuario: usuario,
      );
      _mock.add(m);
      return m;
    }
    // TODO: insert en Supabase + retornar el row creado.
    throw UnimplementedError();
  }
}
