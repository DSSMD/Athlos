// Tipos de movimiento de inventario.
// TODO Den: ajustar/agregar tipos según necesidades reales del negocio.
enum TipoMovimiento {
  ingreso, // entrada manual (compra, recepción)
  salida, // salida manual (uso en producción manual)
  auto, // descuento automático del sistema (orden de producción)
  ajuste, // corrección manual (inventario físico vs registrado)
}

extension TipoMovimientoLabel on TipoMovimiento {
  String get label {
    switch (this) {
      case TipoMovimiento.ingreso:
        return 'Ingreso';
      case TipoMovimiento.salida:
        return 'Salida';
      case TipoMovimiento.auto:
        return 'Auto';
      case TipoMovimiento.ajuste:
        return 'Ajuste';
    }
  }
}

// Áreas operativas del taller textil.
// TODO Den: confirmar/cambiar áreas reales según organización del taller.
enum AreaMovimiento { sublimado, bordado, corte, general }

extension AreaMovimientoLabel on AreaMovimiento {
  String get label {
    switch (this) {
      case AreaMovimiento.sublimado:
        return 'Sublimado';
      case AreaMovimiento.bordado:
        return 'Bordado';
      case AreaMovimiento.corte:
        return 'Corte';
      case AreaMovimiento.general:
        return 'General';
    }
  }
}

class MovimientoModel {
  const MovimientoModel({
    required this.id,
    required this.idInsumo,
    required this.tipo,
    required this.cantidad,
    required this.motivo,
    required this.fecha,
    required this.usuario,
    required this.area,
    required this.referencia,
    required this.stockAntes,
    required this.stockDespues,
  });

  final String id;
  final String idInsumo;
  final TipoMovimiento tipo;
  final double cantidad;
  final String motivo;
  final DateTime fecha;
  final String usuario;
  final AreaMovimiento area;
  final String referencia;
  final double stockAntes;
  final double stockDespues;
}
