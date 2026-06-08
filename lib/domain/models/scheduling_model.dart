// ============================================================================
// lib/domain/models/scheduling_model.dart
// ============================================================================
// Modelos de entrada y salida del algoritmo Moore-Hodgson.
//
// OrdenSchedulingInput : datos que el algoritmo necesita por cada orden.
// OrdenSchedulingResult: resultado por orden tras ejecutar el algoritmo.
// SchedulingResumen    : resumen agregado del resultado completo.
// ============================================================================

/// Datos de entrada del algoritmo Moore-Hodgson para una orden.
///
/// [numOrden]       : identificador único de la orden.
/// [clienteNombre]  : nombre del cliente (solo para display).
/// [fechaEntrega]   : due date d[j] — fecha límite de entrega.
/// [tiempoProceso]  : p[j] en horas — tiempo total de producción de la orden.
///                   Calculado: Σ (cantidad_talla × tiempo_prod_unitario_plantilla).
/// [prioridad]      : 'urgente', 'alta' o 'normal' — usado como desempate en EDD.
/// [fechaOrden]     : fecha de creación (para presentación en UI).
class OrdenSchedulingInput {
  const OrdenSchedulingInput({
    required this.numOrden,
    required this.clienteNombre,
    required this.fechaEntrega,
    required this.tiempoProceso,
    required this.prioridad,
    required this.fechaOrden,
  });

  final String numOrden;
  final String clienteNombre;
  final DateTime fechaEntrega;
  final double tiempoProceso; // horas
  final String prioridad; // 'urgente' | 'alta' | 'normal'
  final DateTime fechaOrden;

  /// Peso numérico de prioridad para desempate en EDD:
  /// urgente = 0, alta = 1, normal = 2 (menor = primero).
  int get pesoPrioridad {
    switch (prioridad) {
      case 'urgente':
        return 0;
      case 'alta':
        return 1;
      default:
        return 2;
    }
  }
}

/// Resultado del algoritmo Moore-Hodgson para una orden.
class OrdenSchedulingResult {
  const OrdenSchedulingResult({
    required this.input,
    required this.posicionSecuencia,
    required this.tiempoInicioEstimado,
    required this.tiempoFinEstimado,
    required this.fechaFinEstimada,
    required this.enTiempo,
  });

  /// Orden original con todos los datos de entrada.
  final OrdenSchedulingInput input;

  /// Posición en la secuencia óptima (1 = primera en producirse).
  /// null si la orden fue "rechazada" (se entregará tarde).
  final int posicionSecuencia;

  /// Horas acumuladas desde el momento del cálculo cuando empieza esta orden.
  final double tiempoInicioEstimado;

  /// Horas acumuladas desde el momento del cálculo cuando termina esta orden.
  final double tiempoFinEstimado;

  /// Fecha calendario de finalización estimada (calculada con capacidad_horas_dia).
  final DateTime fechaFinEstimada;

  /// TRUE = puede entregarse antes de su fecha_entrega.
  /// FALSE = inevitablemente llegará tarde (descartada del conjunto óptimo S).
  final bool enTiempo;

  // ── Aliases de display ──────────────────────────────────────────────────

  String get numOrden => input.numOrden;
  String get clienteNombre => input.clienteNombre;
  DateTime get fechaEntrega => input.fechaEntrega;
  double get tiempoProceso => input.tiempoProceso;
  String get prioridad => input.prioridad;
}

/// Resumen agregado de un resultado de scheduling completo.
class SchedulingResumen {
  const SchedulingResumen({
    required this.totalOrdenes,
    required this.ordenesEnTiempo,
    required this.ordenesConRetraso,
    required this.fechaCalculo,
  });

  final int totalOrdenes;
  final int ordenesEnTiempo;
  final int ordenesConRetraso;
  final DateTime fechaCalculo;

  double get porcentajeEnTiempo =>
      totalOrdenes == 0 ? 100.0 : (ordenesEnTiempo / totalOrdenes) * 100;
}
