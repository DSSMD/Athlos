import 'dart:typed_data';
import '../../../domain/models/detalle_orden_model.dart';

enum OrdenMoneda { bolivianos, dolares }

enum OrdenPrioridad { normal, alta, urgente }

const double kTipoCambioUsdBs = 10.50;

/// LEGACY: ítem aplanado (tipo_prenda + talla) del esquema viejo.
/// Será eliminado en cleanup tras la migración completa a OrdenItemDraft.
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

  String get estado => stockActual >= requerido ? 'disponible' : 'insuficiente';
  double get despues => stockActual - requerido;

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

/// Una talla específica con cantidad, dentro de un OrdenItemDraft.
/// Espejo en el draft de DetalleOrdenTalla.
class OrdenTallaDraft {
  final int idTalla;
  final String nombreTalla;
  final int cantidad;

  const OrdenTallaDraft({
    required this.idTalla,
    required this.nombreTalla,
    required this.cantidad,
  });

  OrdenTallaDraft copyWith({int? idTalla, String? nombreTalla, int? cantidad}) {
    return OrdenTallaDraft(
      idTalla: idTalla ?? this.idTalla,
      nombreTalla: nombreTalla ?? this.nombreTalla,
      cantidad: cantidad ?? this.cantidad,
    );
  }
}

/// Un ítem en el draft del form: o un conjunto, o una plantilla suelta,
/// con sus tallas. Espejo en el draft de DetalleOrden. Se convierte a
/// DetalleOrden al momento de persistir la orden.
class OrdenItemDraft {
  final TipoItem tipoItem;
  final String? idConjunto; // poblado si tipoItem == conjunto
  final String? idPlantilla; // poblado si tipoItem == plantilla
  final String nombre; // denormalizado: nombre del conjunto o plantilla
  final double
  precioUnitario; // viene del catálogo (plantilla.precio_plantilla / conjunto.precio_conjunto)
  final List<OrdenTallaDraft> tallas;

  const OrdenItemDraft({
    required this.tipoItem,
    this.idConjunto,
    this.idPlantilla,
    required this.nombre,
    required this.precioUnitario,
    this.tallas = const [],
  });

  /// Suma de cantidades de todas las tallas del ítem.
  int get cantidadTotal => tallas.fold(0, (sum, t) => sum + t.cantidad);

  /// cantidadTotal × precioUnitario.
  double get subtotal => cantidadTotal * precioUnitario;

  OrdenItemDraft copyWith({
    TipoItem? tipoItem,
    String? idConjunto,
    String? idPlantilla,
    String? nombre,
    double? precioUnitario,
    List<OrdenTallaDraft>? tallas,
  }) {
    return OrdenItemDraft(
      tipoItem: tipoItem ?? this.tipoItem,
      idConjunto: idConjunto ?? this.idConjunto,
      idPlantilla: idPlantilla ?? this.idPlantilla,
      nombre: nombre ?? this.nombre,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      tallas: tallas ?? this.tallas,
    );
  }
}

class OrdenDraft {
  // ───── Información del pedido ─────
  final String? idCliente;
  final DateTime? fechaEntrega;
  final String descripcion;
  final OrdenMoneda moneda;

  // ───── Producto rápido (header del Figma, LEGACY) ─────
  // LEGACY: será eliminado en cleanup tras migración.
  final int? idTipoPrenda;
  final String productoRapidoNombre;
  final int productoRapidoCantidad;
  final double productoRapidoPrecio;
  final String productoRapidoUnidad;

  // ───── Productos (LEGACY esquema viejo) ─────
  // LEGACY: el form actual aún lo usa. Será reemplazado por `items` tras migración.
  final List<OrdenProductoItem> productos;

  // ───── Items (esquema nuevo) ─────
  // Estructura nueva: cada item es conjunto o plantilla con sus tallas.
  final List<OrdenItemDraft> items;

  // ───── Materiales (calculadora) ─────
  final List<OrdenMaterialRequerido> materiales;

  // ───── Lateral ─────
  final OrdenPrioridad prioridad;
  final double anticipo;
  final String metodoPago;

  // ───── IMAGEN ─────
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
    this.items = const [],
    this.materiales = const [],
    this.prioridad = OrdenPrioridad.normal,
    this.anticipo = 0,
    this.metodoPago = 'Transferencia',
    this.imagenBytes,
    this.imagenNombre,
  });

  factory OrdenDraft.empty() => const OrdenDraft();

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
    List<OrdenItemDraft>? items,
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
      items: items ?? this.items,
      materiales: materiales ?? this.materiales,
      prioridad: prioridad ?? this.prioridad,
      anticipo: anticipo ?? this.anticipo,
      metodoPago: metodoPago ?? this.metodoPago,
      idTipoPrenda: idTipoPrenda ?? this.idTipoPrenda,
      imagenBytes: imagenBytes ?? this.imagenBytes,
      imagenNombre: imagenNombre ?? this.imagenNombre,
    );
  }

  /// LEGACY: subtotal del esquema viejo (productos). Se mantiene mientras
  /// el form actual aún use OrdenProductoItem.
  double get subtotal => productos.fold(0, (sum, p) => sum + p.subtotal);

  /// Subtotal calculado sobre los items del esquema nuevo.
  /// Reemplazará a `subtotal` cuando se complete la migración del form.
  double get subtotalItems => items.fold(0, (sum, i) => sum + i.subtotal);

  /// LEGACY: validación basada en productos. Se mantiene mientras el form
  /// actual aún use OrdenProductoItem.
  bool get esValido {
    return idCliente != null && fechaEntrega != null && productos.isNotEmpty;
  }

  /// Validación basada en el esquema nuevo (items).
  /// Reemplazará a `esValido` cuando se complete la migración del form.
  bool get esValidoItems {
    return idCliente != null && fechaEntrega != null && items.isNotEmpty;
  }

  String formatPrecio(double valorEnBs) {
    if (moneda == OrdenMoneda.dolares) {
      double valorUsd = valorEnBs / kTipoCambioUsdBs;
      return "\$ ${valorUsd.toStringAsFixed(2)}";
    }
    return "Bs ${valorEnBs.toStringAsFixed(2)}";
  }
}
