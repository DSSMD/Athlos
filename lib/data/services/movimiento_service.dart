// MOCK — eliminar / reemplazar con Supabase cuando exista tabla
// `movimiento_insumo`. La lista vive en memoria del proceso, se pierde al
// reiniciar la app.
//
// IMPORTANTE: `idInsumo` matchea con `InventarioItemModel.id` (no con codigo).
// Los IDs del seed actual de inventario son '1', '2', ..., '10'.

import '../../domain/models/movimiento_model.dart';

class MovimientoService {
  MovimientoService();

  static const bool _useMockData = true;

  // Lista mockeada en memoria con datos variados para verificar la UI del
  // tab Movimientos. Si _useMockData = false, esto nunca se usa.
  final List<MovimientoModel> _mock = _seedMovimientos();

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
    required AreaMovimiento area,
    required double stockAntes,
  }) async {
    // Calcular stock después según tipo.
    // TODO Den: confirmar comportamiento exacto para `ajuste` (positivo o
    // negativo según signo de cantidad). Por ahora ajuste se trata como
    // delta positivo (suma).
    final double stockDespues;
    switch (tipo) {
      case TipoMovimiento.ingreso:
      case TipoMovimiento.ajuste:
        stockDespues = stockAntes + cantidad;
        break;
      case TipoMovimiento.salida:
      case TipoMovimiento.auto:
        stockDespues = stockAntes - cantidad;
        break;
    }

    // Auto-generar referencia "Manual #M-XXX" para movimientos creados
    // desde el form. TODO Den: ajustar formato o conectar con sistema de
    // órdenes/compras cuando exista backend.
    final manualesCount = _mock
        .where((m) => m.referencia.startsWith('Manual #M-'))
        .length;
    final referencia =
        'Manual #M-${(manualesCount + 1).toString().padLeft(3, '0')}';

    final nuevo = MovimientoModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      idInsumo: idInsumo,
      tipo: tipo,
      cantidad: cantidad,
      motivo: motivo,
      fecha: DateTime.now(),
      usuario: usuario,
      area: area,
      referencia: referencia,
      stockAntes: stockAntes,
      stockDespues: stockDespues,
    );

    if (_useMockData) {
      _mock.add(nuevo);
    } else {
      // TODO: insert en Supabase + retornar el row creado.
      throw UnimplementedError();
    }

    return nuevo;
  }
}

// ─── MOCK SEED ────────────────────────────────────────────────────────────────

List<MovimientoModel> _seedMovimientos() {
  final now = DateTime.now();
  DateTime daysAgo(int d) => now.subtract(Duration(days: d));

  return [
    // ─── INGRESOS (3) ─────────────────────────────────────────────────────
    MovimientoModel(
      id: '1',
      idInsumo: '1', // Tela algodón blanco
      tipo: TipoMovimiento.ingreso,
      cantidad: 500,
      motivo: 'Compra mensual',
      fecha: daysAgo(8),
      usuario: 'Ana T.',
      area: AreaMovimiento.general,
      referencia: 'Compra #C-089',
      stockAntes: 380,
      stockDespues: 880,
    ),
    MovimientoModel(
      id: '2',
      idInsumo: '5', // Cierres metálicos 20cm
      tipo: TipoMovimiento.ingreso,
      cantidad: 1000,
      motivo: 'Compra para producción',
      fecha: daysAgo(9),
      usuario: 'Ana T.',
      area: AreaMovimiento.general,
      referencia: 'Compra #C-088',
      stockAntes: 890,
      stockDespues: 1890,
    ),
    MovimientoModel(
      id: '3',
      idInsumo: '4', // Botones plástico 4H
      tipo: TipoMovimiento.ingreso,
      cantidad: 2000,
      motivo: 'Reposición de stock',
      fecha: daysAgo(15),
      usuario: 'Jorge R.',
      area: AreaMovimiento.general,
      referencia: 'Compra #C-087',
      stockAntes: 4000,
      stockDespues: 6000,
    ),

    // ─── SALIDAS (5) ──────────────────────────────────────────────────────
    MovimientoModel(
      id: '4',
      idInsumo: '1', // Tela algodón blanco
      tipo: TipoMovimiento.salida,
      cantidad: 50,
      motivo: 'Producción remera blanca M',
      fecha: daysAgo(2),
      usuario: 'Carlos M.',
      area: AreaMovimiento.corte,
      referencia: '#ORD-2846',
      stockAntes: 880,
      stockDespues: 830,
    ),
    MovimientoModel(
      id: '5',
      idInsumo: '2', // Tela poliéster azul
      tipo: TipoMovimiento.salida,
      cantidad: 30,
      motivo: 'Producción uniforme escolar',
      fecha: daysAgo(3),
      usuario: 'Carlos M.',
      area: AreaMovimiento.corte,
      referencia: '#ORD-2845',
      stockAntes: 75,
      stockDespues: 45,
    ),
    MovimientoModel(
      id: '6',
      idInsumo: '3', // Hilo negro #120
      tipo: TipoMovimiento.salida,
      cantidad: 8,
      motivo: 'Bordado lote 12 polos',
      fecha: daysAgo(5),
      usuario: 'Rosa M.',
      area: AreaMovimiento.bordado,
      referencia: '#ORD-2843',
      stockAntes: 20,
      stockDespues: 12,
    ),
    MovimientoModel(
      id: '7',
      idInsumo: '6', // Elástico 3cm
      tipo: TipoMovimiento.salida,
      cantidad: 25,
      motivo: 'Pretina pantalón deportivo',
      fecha: daysAgo(6),
      usuario: 'Rosa M.',
      area: AreaMovimiento.corte,
      referencia: '#ORD-2842',
      stockAntes: 50,
      stockDespues: 25,
    ),
    MovimientoModel(
      id: '8',
      idInsumo: '10', // Tela drill caqui
      tipo: TipoMovimiento.salida,
      cantidad: 40,
      motivo: 'Producción pantalón cargo',
      fecha: daysAgo(11),
      usuario: 'Carlos M.',
      area: AreaMovimiento.corte,
      referencia: '#ORD-2840',
      stockAntes: 240,
      stockDespues: 200,
    ),

    // ─── AUTO (3) — descuentos automáticos del sistema ────────────────────
    MovimientoModel(
      id: '9',
      idInsumo: '9', // Hilo blanco #100
      tipo: TipoMovimiento.auto,
      cantidad: 12,
      motivo: 'Descuento automático orden #ORD-2844',
      fecha: daysAgo(4),
      usuario: 'Sistema',
      area: AreaMovimiento.bordado,
      referencia: 'Sistema',
      stockAntes: 70,
      stockDespues: 58,
    ),
    MovimientoModel(
      id: '10',
      idInsumo: '5', // Cierres metálicos
      tipo: TipoMovimiento.auto,
      cantidad: 100,
      motivo: 'Descuento automático orden #ORD-2841',
      fecha: daysAgo(7),
      usuario: 'Sistema',
      area: AreaMovimiento.sublimado,
      referencia: 'Sistema',
      stockAntes: 1990,
      stockDespues: 1890,
    ),
    MovimientoModel(
      id: '11',
      idInsumo: '4', // Botones
      tipo: TipoMovimiento.auto,
      cantidad: 200,
      motivo: 'Descuento automático orden #ORD-2839',
      fecha: daysAgo(13),
      usuario: 'Sistema',
      area: AreaMovimiento.sublimado,
      referencia: 'Sistema',
      stockAntes: 4200,
      stockDespues: 4000,
    ),

    // ─── AJUSTE (1) ───────────────────────────────────────────────────────
    MovimientoModel(
      id: '12',
      idInsumo: '3', // Hilo negro #120
      tipo: TipoMovimiento.ajuste,
      cantidad: 5,
      motivo: 'Conteo físico — diferencia detectada',
      fecha: daysAgo(1),
      usuario: 'Jorge R.',
      area: AreaMovimiento.general,
      referencia: 'Ajuste manual',
      stockAntes: 7,
      stockDespues: 12,
    ),
  ];
}
