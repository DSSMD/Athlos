import 'detalle_orden_model.dart';

/// LEGACY: ítem aplanado del esquema viejo (desglose_tallas).
/// Mantenido en el modelo para no romper la UI que aún lo consume.
/// En el flujo nuevo (fromJson), esta lista queda vacía — la UI debe migrar
/// a `detalleOrden` (la estructura nueva).
class TallaDetalle {
  final int idTipoPrenda;
  final String nombrePrenda;
  final String nombreTalla;
  final int cantidad;
  final double precioUnitario;

  TallaDetalle({
    required this.idTipoPrenda,
    required this.nombrePrenda,
    required this.nombreTalla,
    required this.cantidad,
    this.precioUnitario = 0.0,
  });
}

class OrdenModel {
  final String numOrden;

  // ───── Información del Cliente ─────
  final String idCliente;
  final String? clienteCi;
  final String clienteNombre;
  final String? clienteTelefono;
  final String? clienteEmail;
  final String? clienteDireccion;

  // ───── Estados ─────
  final int idEstado;
  final String estadoOrden;
  final int? idEstadoPago;
  final String estadoPago;

  // ───── Fechas y costos ─────
  final DateTime fechaOrden;
  final DateTime fechaEntrega;
  final double? tiempoProcesamientoEstimado;
  final double costoTotal;

  // ───── Prioridad ─────
  /// Valores esperados de la BD: 'urgente', 'alta', 'normal'.
  /// Se normaliza a minúsculas y cae a 'normal' cuando viene null
  /// (registros viejos previos al ALTER TABLE).
  final String prioridad;

  // ───── Resumen denormalizado (LEGACY: derivado en fromJson para listas) ─────
  /// LEGACY: resumen de productos para listas (ej: "Deportivo (10), Polera (8)").
  /// Se calcula derivado de detalleOrden en fromJson.
  final String producto;

  /// LEGACY: cantidad total a través de todos los items.
  /// Se calcula derivado de detalleOrden en fromJson.
  final int cantidad;

  // ───── Items (esquema nuevo) ─────
  /// Items de la orden mapeados desde detalle_orden con sus tallas y
  /// composiciones internas (para conjuntos).
  final List<DetalleOrden> detalleOrden;

  // ───── LEGACY (esquema viejo, queda vacío en flujo nuevo) ─────
  /// LEGACY: lista plana de tallas del esquema viejo (desglose_tallas).
  /// Queda vacía en el flujo nuevo; la UI debe migrar a `detalleOrden`.
  final List<TallaDetalle> desgloseTallas;

  // ───── Notas e imagen ─────
  final String notasAdicionales;

  /// Imagen del modelo: ahora viene directo de la columna orden.imagen_modelo
  /// (antes venía de ficha_tecnica.imagen_modelo, tabla ya inexistente).
  final String? imagenModelo;

  OrdenModel({
    required this.numOrden,
    required this.idCliente,
    required this.clienteNombre,
    this.clienteTelefono,
    required this.idEstado,
    required this.estadoOrden,
    this.idEstadoPago,
    required this.estadoPago,
    required this.fechaOrden,
    required this.fechaEntrega,
    this.tiempoProcesamientoEstimado,
    required this.costoTotal,
    this.prioridad = 'normal',
    required this.producto,
    required this.cantidad,
    this.detalleOrden = const [],
    this.desgloseTallas = const [],
    this.imagenModelo,
    this.notasAdicionales = '',
    this.clienteEmail,
    this.clienteDireccion,
    this.clienteCi,
  });

  factory OrdenModel.fromJson(Map<String, dynamic> json) {
    // ─── Cliente ───
    final cliente = json['cliente'] as Map<String, dynamic>?;
    final nombre = cliente?['nom_cliente'] ?? '';
    final apellido = cliente?['apellido_cliente'] ?? '';

    // ─── Estados ───
    final eOrden = json['estado_orden'] as Map<String, dynamic>?;
    final ePago = json['estado_pago'] as Map<String, dynamic>?;

    // ─── Items (esquema nuevo) ───
    // Cuando el service esté reescrito a la nueva query, este array vendrá
    // poblado con los detalle_orden + sus tallas + composicion_interna.
    final detalleRaw = json['detalle_orden'] as List<dynamic>? ?? [];
    final List<DetalleOrden> detalleParsed = detalleRaw
        .map((d) => DetalleOrden.fromJson(d as Map<String, dynamic>))
        .toList();

    // ─── Resumen derivado (para campos legacy producto y cantidad) ───
    final int totalCant = detalleParsed.fold(
      0,
      (sum, d) => sum + d.tallas.fold(0, (s, t) => s + t.cantidad),
    );

    String resumen = 'Sin productos';
    if (detalleParsed.isNotEmpty) {
      final lista = detalleParsed
          .map((d) => '${d.nombreItem} (${d.cantidadTotal})')
          .toList();
      if (lista.length <= 2) {
        resumen = lista.join(', ');
      } else {
        resumen = '${lista[0]}, ${lista[1]} y ${lista.length - 2} más...';
      }
    }

    return OrdenModel(
      numOrden: json['num_orden'] ?? '',
      idCliente: json['id_cliente'] ?? '',
      clienteNombre: '$nombre $apellido'.trim(),
      clienteTelefono: cliente?['num_telefono'],
      clienteEmail: cliente?['email'],
      clienteDireccion: cliente?['direccion'],
      // FIX: el schema de Supabase tiene la columna ci_cliente, no ci.
      // Antes leía cliente?['ci'] y siempre devolvía null.
      clienteCi: cliente?['ci_cliente'],
      idEstado: json['id_estado'] ?? 0,
      estadoOrden: eOrden?['nombre_estado'] ?? 'Desconocido',
      idEstadoPago: (json['id_estado_pago'] as num?)?.toInt(),
      estadoPago: ePago?['nombre_estado'] ?? 'Pendiente',
      fechaOrden: DateTime.parse(json['fecha_orden']),
      fechaEntrega: DateTime.parse(json['fecha_entrega']),
      tiempoProcesamientoEstimado:
          (json['tiempo_procesamiento_estimado'] as num?)?.toDouble(),
      costoTotal: (json['costo_total'] as num?)?.toDouble() ?? 0.0,
      prioridad: (json['prioridad'] as String?)?.toLowerCase() ?? 'normal',
      producto: resumen,
      cantidad: totalCant,
      detalleOrden: detalleParsed,
      desgloseTallas: const [], // LEGACY: vacío en el flujo nuevo
      imagenModelo: json['imagen_modelo'] as String?,
      notasAdicionales: json['notas_adicionales'] ?? '',
    );
  }
}

/// Método copyWith útil para cuando queramos cambiar solo el estado de la orden en la UI
/*OrdenModel copyWith({
    String? numOrden,
    String? clienteNombre,
    DateTime? fechaOrden,
    DateTime? fechaEntrega,
    double? costoTotal,
    String? estadoOrden,
    String? estadoPago,
    String? producto,
    int? cantidad,
  }) {
    return OrdenModel(
      numOrden: numOrden ?? this.numOrden,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      fechaOrden: fechaOrden ?? this.fechaOrden,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      costoTotal: costoTotal ?? this.costoTotal,
      estadoOrden: estadoOrden ?? this.estadoOrden,
      estadoPago: estadoPago ?? this.estadoPago,
      producto: producto ?? this.producto,
      cantidad: cantidad ?? this.cantidad,
      idCliente: idCliente ?? this.idCliente,
      idEstado: idEstado ?? this.idEstado,
      idEstadoPago: idEstadoPago ?? this.idEstadoPago,
    );
  }*/
