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

/// Tipo de cambio mockeado USD -> Bs.
/// TODO(SCRUM-75): cuando exista config global o endpoint del banco,
/// reemplazar por valor real. Hoy hardcoded a 6.96 según mockup.
const double kTipoCambioUsdBs = 6.96;

/// Item de producto dentro de la orden (mock — backend no expone tabla).
/// Mismo concepto que OrdenItem en orden_items_editor.dart pero independiente
/// para no acoplar la lógica del editor de SCRUM-72 con este form.
class OrdenProductoItem {
  final String nombre;
  final int cantidad;
  final double precioUnitario;
  final String unidad; // "uds", "mts", "kg", etc.

  const OrdenProductoItem({
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
    this.unidad = 'uds',
  });

  double get subtotal => cantidad * precioUnitario;
}

/// Material requerido calculado para esta orden (mock — Figma).
/// TODO(SCRUM-75): cuando exista tabla `material` y relación
/// `producto_material` en BD, calcular dinámicamente desde productos.
class OrdenMaterialRequerido {
  final String material;
  final double requerido;
  final double stockActual;
  final String unidad;

  const OrdenMaterialRequerido({
    required this.material,
    required this.requerido,
    required this.stockActual,
    required this.unidad,
  });

  double get despues => stockActual - requerido;

  /// Estado del material: 'disponible', 'justo', 'insuficiente'.
  String get estado {
    if (despues < 0) return 'insuficiente';
    if (despues < requerido * 0.3) return 'justo';
    return 'disponible';
  }
}

/// Borrador de orden. State local del form de creación.
///
/// Inmutable: cada cambio devuelve una copia con `copyWith` para que el
/// padre haga `setState` y el form se redibuje. Mismo patrón que clientes.
class OrdenDraft {
  // ───── Información del pedido ─────
  final String? idCliente;
  final DateTime? fechaEntrega;
  final String descripcion;
  final OrdenMoneda moneda;

  // ───── Producto rápido (header del Figma) ─────
  // El Figma duplica producto/cantidad/precio en el header de "Información"
  // Y en la tabla "Productos de la orden". Mantenemos los dos según diseño.
  final String productoRapidoNombre;
  final int productoRapidoCantidad;
  final double productoRapidoPrecio;
  final String productoRapidoUnidad;

  // ───── Productos ─────
  final List<OrdenProductoItem> productos;

  // ───── Materiales (calculadora) ─────
  final List<OrdenMaterialRequerido> materiales;

  // ───── Lateral ─────
  final OrdenPrioridad prioridad;
  final double anticipo;
  final String metodoPago;

  const OrdenDraft({
    this.idCliente,
    this.fechaEntrega,
    this.descripcion = '',
    this.moneda = OrdenMoneda.bolivianos,
    this.productoRapidoNombre = '',
    this.productoRapidoCantidad = 0,
    this.productoRapidoPrecio = 0,
    this.productoRapidoUnidad = 'Unidades',
    this.productos = const [],
    this.materiales = const [],
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
    String? productoRapidoNombre,
    int? productoRapidoCantidad,
    double? productoRapidoPrecio,
    String? productoRapidoUnidad,
    List<OrdenProductoItem>? productos,
    List<OrdenMaterialRequerido>? materiales,
    OrdenPrioridad? prioridad,
    double? anticipo,
    String? metodoPago,
  }) {
    return OrdenDraft(
      idCliente: idCliente ?? this.idCliente,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      descripcion: descripcion ?? this.descripcion,
      moneda: moneda ?? this.moneda,
      productoRapidoNombre: productoRapidoNombre ?? this.productoRapidoNombre,
      productoRapidoCantidad:
          productoRapidoCantidad ?? this.productoRapidoCantidad,
      productoRapidoPrecio: productoRapidoPrecio ?? this.productoRapidoPrecio,
      productoRapidoUnidad: productoRapidoUnidad ?? this.productoRapidoUnidad,
      productos: productos ?? this.productos,
      materiales: materiales ?? this.materiales,
      prioridad: prioridad ?? this.prioridad,
      anticipo: anticipo ?? this.anticipo,
      metodoPago: metodoPago ?? this.metodoPago,
    );
  }

  /// Subtotal: suma de subtotales de productos.
  double get subtotal => productos.fold(0, (sum, p) => sum + p.subtotal);

  /// Validación mínima para habilitar el botón "Crear orden".
  bool get esValido {
    return idCliente != null && fechaEntrega != null && productos.isNotEmpty;
  }

  /// Helper para formatear precios según moneda actual.
  String formatPrecio(double valor) {
    if (moneda == OrdenMoneda.dolares) {
      return '\$${valor.toStringAsFixed(2)}';
    }
    return 'Bs. ${valor.toStringAsFixed(2)}';
  }
}
