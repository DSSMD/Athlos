// ============================================================================
// orden_draft.dart
// Ubicación: lib/presentation/components/ordenes/orden_draft.dart
// Descripción: State local del formulario "Nueva orden" (SCRUM-75).
//
// NO es un modelo de BD. Es la representación rica del form mientras el
// usuario lo está llenando, con todos los campos que pide el Figma.
// Cuando se aprieta "Crear orden", este draft se mappea a OrdenModel
// (los 7 campos que sí existen en BD) y los campos extra quedan como
// Ver HANDOFF — patrón "placeholders honestos con TODOs".
// ============================================================================

import 'dart:typed_data';

/// Moneda de la orden. El Figma muestra toggle Bs / USD.
enum OrdenMoneda { bolivianos, dolares }

/// Prioridad de la orden. El Figma muestra Normal / Alta / Urgente.
enum OrdenPrioridad { normal, alta, urgente }

/// Tipo de cambio mockeado USD -> Bs.
const double kTipoCambioUsdBs = 10.50;

class OrdenProductoItem {
  final int? idTipoPrenda;
  final int? idTalla;
  final String nombre;
  final int cantidad;
  final double precioUnitario;
  final String unidad;

  const OrdenProductoItem({
    this.idTipoPrenda,
    this.idTalla,
    required this.nombre,
    required this.cantidad,
    this.precioUnitario = 0.0,
    this.unidad = 'uds',
  });

  double get subtotal => cantidad * precioUnitario;

  OrdenProductoItem copyWith({
    int? idTipoPrenda,
    int? idTalla,
    String? nombre,
    int? cantidad,
    double? precioUnitario,
  }) {
    return OrdenProductoItem(
      idTipoPrenda: idTipoPrenda ?? this.idTipoPrenda,
      idTalla: idTalla ?? this.idTalla,
      nombre: nombre ?? this.nombre,
      cantidad: cantidad ?? this.cantidad,
      precioUnitario: precioUnitario ?? this.precioUnitario,
    );
  }
}

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

  // Lógica de estado automática
  String get estado => stockActual >= requerido ? 'disponible' : 'insuficiente';
  double get despues => stockActual - requerido;

  // ESTO ES LO QUE FALTA:
  OrdenMaterialRequerido copyWith({
    String? material,
    double? requerido,
    double? stockActual,
    String? unidad,
  }) {
    return OrdenMaterialRequerido(
      material: material ?? this.material,
      requerido: requerido ?? this.requerido,
      stockActual: stockActual ?? this.stockActual,
      unidad: unidad ?? this.unidad,
    );
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
  final int? idTipoPrenda;
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

  // ───── IMAGEN  ─────
  final Uint8List? imagenBytes;
  final String? imagenNombre;

  const OrdenDraft({
    this.idCliente,
    this.fechaEntrega,
    this.descripcion = '',
    this.moneda = OrdenMoneda.bolivianos,

    this.idTipoPrenda,
    this.productoRapidoNombre = '',
    this.productoRapidoCantidad = 0,
    this.productoRapidoPrecio = 0,
    this.productoRapidoUnidad = 'Unidades',
    this.productos = const [],
    this.materiales = const [],
    this.prioridad = OrdenPrioridad.normal,
    this.anticipo = 0,
    this.metodoPago = 'Transferencia',
    this.imagenBytes,
    this.imagenNombre,
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
    int? idTipoPrenda,
    Uint8List? imagenBytes,
    String? imagenNombre,
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
      idTipoPrenda: idTipoPrenda ?? this.idTipoPrenda,
      imagenBytes: imagenBytes ?? this.imagenBytes,
      imagenNombre: imagenNombre ?? this.imagenNombre,
    );
  }

  /// Subtotal: suma de subtotales de productos.
  double get subtotal => productos.fold(0, (sum, p) => sum + p.subtotal);

  /// Validación mínima para habilitar el botón "Crear orden".
  bool get esValido {
    return idCliente != null && fechaEntrega != null && productos.isNotEmpty;
  }

  //int? get idTipoPrenda => null;

  /// Helper para formatear precios según moneda actual.
  // En lib/presentation/components/ordenes/orden_draft.dart

  String formatPrecio(double valorEnBs) {
    if (moneda == OrdenMoneda.dolares) {
      double valorUsd = valorEnBs / kTipoCambioUsdBs;
      return "\$ ${valorUsd.toStringAsFixed(2)}";
    }
    return "Bs ${valorEnBs.toStringAsFixed(2)}";
  }
}
