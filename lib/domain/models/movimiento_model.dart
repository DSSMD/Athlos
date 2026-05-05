enum TipoMovimiento { ingreso, salida }

extension TipoMovimientoLabel on TipoMovimiento {
  String get label {
    switch (this) {
      case TipoMovimiento.ingreso:
        return 'Ingreso';
      case TipoMovimiento.salida:
        return 'Salida';
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
  });

  final String id;
  final String idInsumo;
  final TipoMovimiento tipo;
  final double cantidad;
  final String motivo;
  final DateTime fecha;
  final String usuario;
}
