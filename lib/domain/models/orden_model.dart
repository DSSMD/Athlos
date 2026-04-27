class OrdenModel {
  final String numOrden;

  // Información del Cliente (ID + Nombre para visualización)
  final String idCliente;
  final String clienteNombre;
  final String?
  clienteTelefono; // Útil para contactar al cliente desde la lista

  // Estados (ID para lógica/update + Nombre para la UI)
  final int idEstado;
  final String estadoOrden;
  final int idEstadoPago;
  final String estadoPago;

  final DateTime fechaOrden;
  final DateTime fechaEntrega;
  final double costoTotal;
  final String producto;
  final int cantidad;
  final String? notas;

  OrdenModel({
    required this.numOrden,
    required this.idCliente,
    required this.clienteNombre,
    this.clienteTelefono,
    required this.idEstado,
    required this.estadoOrden,
    required this.idEstadoPago,
    required this.estadoPago,
    required this.fechaOrden,
    required this.fechaEntrega,
    required this.costoTotal,
    required this.producto,
    required this.cantidad,
    this.notas,
  });

  factory OrdenModel.fromJson(Map<String, dynamic> json) {
    // Manejo de Cliente
    final cliente = json['cliente'] as Map<String, dynamic>?;
    final nombre = cliente?['nom_cliente'] ?? '';
    final apellido = cliente?['apellido_cliente'] ?? '';

    // Manejo de Estados
    final eOrden = json['estado_orden'] as Map<String, dynamic>?;
    final ePago = json['estado_pago'] as Map<String, dynamic>?;

    // Manejo de Producto y Cantidad (como en el anterior)
    String productoNombre = 'Sin especificar';
    if (json['ficha_tecnica'] != null &&
        (json['ficha_tecnica'] as List).isNotEmpty) {
      final tipo = json['ficha_tecnica'][0]['tipo_prenda'];
      productoNombre = tipo?['nombre_prenda'] ?? 'Prenda';
    }

    int totalCant = 0;
    if (json['desglose_tallas'] != null) {
      for (var t in (json['desglose_tallas'] as List)) {
        totalCant += (t['cantidad'] as num).toInt();
      }
    }

    return OrdenModel(
      numOrden: json['num_orden'] ?? '',
      idCliente: json['id_cliente'] ?? '',
      clienteNombre: '$nombre $apellido'.trim(),
      clienteTelefono: cliente?['num_telefono'],
      idEstado: json['id_estado'] ?? 0,
      estadoOrden: eOrden?['nombre_estado'] ?? 'Desconocido',
      idEstadoPago: json['id_estado_pago'] ?? 0,
      estadoPago: ePago?['nombre_estado'] ?? 'Pendiente',
      fechaOrden: DateTime.parse(json['fecha_orden']),
      fechaEntrega: DateTime.parse(json['fecha_entrega']),
      costoTotal: (json['costo_total'] as num).toDouble(),
      producto: productoNombre,
      cantidad: totalCant,
      notas: json['notas_adicionales'],
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
  