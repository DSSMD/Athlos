// lib/domain/models/balance_model.dart

/// Resumen global del balance financiero para un período dado.
class ResumenBalanceModel {
  final double ingresosTotales;   // Suma de orden.costo_total en el período
  final double egresosTotales;    // Suma de pagos_trabajador.monto en el período
  final double balanceNeto;       // ingresosTotales - egresosTotales

  const ResumenBalanceModel({
    required this.ingresosTotales,
    required this.egresosTotales,
  }) : balanceNeto = ingresosTotales - egresosTotales;
}

/// Representa una orden con su costo de venta y cuánto costó producirla,
/// permitiendo calcular la ganancia por orden.
class OrdenBalanceModel {
  final String numOrden;
  final String clienteNombre;
  final DateTime fechaOrden;
  final String estadoOrden;
  final String estadoPago;

  /// Ingreso: lo que el cliente pagó (orden.costo_total)
  final double ingresoVenta;

  /// Egreso: lo que se pagó a trabajadores por esta orden
  /// (suma de pagos_trabajador.monto con asignaciones de esta orden)
  final double costoProduccion;

  /// Ganancia bruta = ingresoVenta - costoProduccion
  double get ganancia => ingresoVenta - costoProduccion;

  /// Margen de ganancia en porcentaje
  double get margenPorcentaje =>
      ingresoVenta > 0 ? (ganancia / ingresoVenta) * 100 : 0.0;

  const OrdenBalanceModel({
    required this.numOrden,
    required this.clienteNombre,
    required this.fechaOrden,
    required this.estadoOrden,
    required this.estadoPago,
    required this.ingresoVenta,
    required this.costoProduccion,
  });
}

/// Enum de períodos disponibles para filtrar el balance
enum BalancePeriodo {
  semana,
  mes,
  trimestre,
  todo,
}

extension BalancePeriodoExt on BalancePeriodo {
  String get label {
    switch (this) {
      case BalancePeriodo.semana:
        return 'Semana';
      case BalancePeriodo.mes:
        return 'Mes';
      case BalancePeriodo.trimestre:
        return '3 Meses';
      case BalancePeriodo.todo:
        return 'Todo';
    }
  }

  /// Devuelve la fecha de inicio del período a partir de ahora.
  /// Retorna null si es [BalancePeriodo.todo].
  DateTime? get fechaDesde {
    final now = DateTime.now();
    switch (this) {
      case BalancePeriodo.semana:
        return now.subtract(const Duration(days: 7));
      case BalancePeriodo.mes:
        return DateTime(now.year, now.month - 1, now.day);
      case BalancePeriodo.trimestre:
        return DateTime(now.year, now.month - 3, now.day);
      case BalancePeriodo.todo:
        return null;
    }
  }
}
