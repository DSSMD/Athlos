// ============================================================================
// orden_draft.dart
// Ubicación: lib/presentation/components/ordenes/orden_draft.dart
// Descripción: State local del formulario "Nueva orden" (SCRUM-75).
//
// NO es un modelo de BD. Es la representación rica del form mientras el
// usuario lo está llenando, con todos los campos que pide el Figma.
// Cuando se aprieta "Crear orden", este draft se mappea a OrdenModel
// (los 7 campos que sí existen en BD) y los campos extra quedan como
// TODO documentado hasta que el backend los exponga.
//
// Ver HANDOFF — patrón "placeholders honestos con TODOs".
// ============================================================================

/// Moneda de la orden. El Figma muestra toggle Bs / USD.
enum OrdenMoneda { bolivianos, dolares }

/// Prioridad de la orden. El Figma muestra Normal / Alta / Urgente.
enum OrdenPrioridad { normal, alta, urgente }

/// Borrador de orden. State local del form de creación.
///
/// Inmutable: cada cambio devuelve una copia con `copyWith` para que el
/// padre haga `setState` y el form se redibuje. Mismo patrón que clientes.
class OrdenDraft {
  // ───── Información del pedido ─────
  final String? idCliente; // null hasta que se seleccione
  final DateTime? fechaEntrega;
  final String descripcion;
  final OrdenMoneda moneda;

  // ───── Productos ─────
  // (Bloque 2) — Vacío hoy. Se llenará con la card "Productos de la orden".
  // final List<OrdenItem> productos;

  // ───── Materiales ─────
  // (Bloque 2) — Calculadora. Mockeado.

  // ───── Lateral ─────
  final OrdenPrioridad prioridad;
  final double anticipo;
  final String metodoPago;

  const OrdenDraft({
    this.idCliente,
    this.fechaEntrega,
    this.descripcion = '',
    this.moneda = OrdenMoneda.bolivianos,
    this.prioridad = OrdenPrioridad.normal,
    this.anticipo = 0,
    this.metodoPago = 'Transferencia',
  });

  /// Draft vacío inicial.
  factory OrdenDraft.empty() => const OrdenDraft();

  /// Copia con cambios. Patrón estándar para state inmutable.
  OrdenDraft copyWith({
    String? idCliente,
    DateTime? fechaEntrega,
    String? descripcion,
    OrdenMoneda? moneda,
    OrdenPrioridad? prioridad,
    double? anticipo,
    String? metodoPago,
  }) {
    return OrdenDraft(
      idCliente: idCliente ?? this.idCliente,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      descripcion: descripcion ?? this.descripcion,
      moneda: moneda ?? this.moneda,
      prioridad: prioridad ?? this.prioridad,
      anticipo: anticipo ?? this.anticipo,
      metodoPago: metodoPago ?? this.metodoPago,
    );
  }

  /// Validación mínima para habilitar el botón "Crear orden".
  /// (Bloque 5) — Se completará cuando estén todos los cards.
  bool get esValido {
    return idCliente != null && fechaEntrega != null;
  }
}
