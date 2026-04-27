class TallaDetalle {
  final String nombrePrenda;
  final String nombreTalla;
  final int cantidad;
  TallaDetalle({
    required this.nombrePrenda,
    required this.nombreTalla,
    required this.cantidad,
  });
}

class OrdenModel {
  final String numOrden;

  // Información del Cliente
  final String idCliente;
  final String? clienteCi;
  final String clienteNombre;
  final String? clienteTelefono;
  final String? clienteEmail;
  final String? clienteDireccion;

  // Estados
  final int idEstado;
  final String estadoOrden;
  final int idEstadoPago;
  final String estadoPago;

  final DateTime fechaOrden;
  final DateTime fechaEntrega;
  final double costoTotal;
  final String producto;
  final int cantidad;

  // Lista de tallas y notas
  final List<TallaDetalle> desgloseTallas;
  final String notasAdicionales;

  // Imagen de la Ficha Técnica
  final String? imagenModelo;

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
    required this.desgloseTallas,
    this.imagenModelo,
    this.notasAdicionales = '',
    this.clienteEmail,
    this.clienteDireccion,
    this.clienteCi,
  });

  factory OrdenModel.fromJson(Map<String, dynamic> json) {
    // Manejo de Cliente
    final cliente = json['cliente'] as Map<String, dynamic>?;
    final nombre = cliente?['nom_cliente'] ?? '';
    final apellido = cliente?['apellido_cliente'] ?? '';

    // Manejo de Estados
    final eOrden = json['estado_orden'] as Map<String, dynamic>?;
    final ePago = json['estado_pago'] as Map<String, dynamic>?;

    String productoNombre = 'Sin especificar';
    String? img;

    // Extraemos la imagen de la primera ficha técnica (si la hay)
    if (json['ficha_tecnica'] != null &&
        (json['ficha_tecnica'] as List).isNotEmpty) {
      final ficha = json['ficha_tecnica'][0];
      final tipo = ficha['tipo_prenda'];
      productoNombre = tipo?['nombre_prenda'] ?? 'Prenda';
      img = ficha['imagen_modelo'];
    }

    int totalCant = 0;
    List<TallaDetalle> tallasReales = [];

    Map<String, int> conteoProductos = {};

    // Manejo de Tallas
    if (json['desglose_tallas'] != null) {
      for (var t in (json['desglose_tallas'] as List)) {
        int cant = (t['cantidad'] as num).toInt();
        totalCant += cant;

        String nombrePrenda = t['tipo_prenda']?['nombre_prenda'] ?? 'Prenda';

        tallasReales.add(
          TallaDetalle(
            nombrePrenda: nombrePrenda,
            nombreTalla: t['tallas']?['nombre_talla'] ?? '?',
            cantidad: cant,
          ),
        );

        conteoProductos[nombrePrenda] =
            (conteoProductos[nombrePrenda] ?? 0) + cant;
      }
    }

    String resumenProductos = productoNombre;

    if (conteoProductos.isNotEmpty) {
      // Convertimos el mapa en una lista de textos: ["Camisa (2)", "Short (3)"]
      List<String> listaResumen = conteoProductos.entries
          .map((e) => '${e.key} (${e.value})')
          .toList();

      // Lógica para no saturar la fila
      if (listaResumen.length <= 2) {
        resumenProductos = listaResumen.join(', ');
      } else {
        // Si son 3 o más, mostramos los dos primeros y un indicativo
        resumenProductos =
            '${listaResumen[0]}, ${listaResumen[1]} y ${listaResumen.length - 2} más...';
      }
    }

    return OrdenModel(
      numOrden: json['num_orden'] ?? '',
      idCliente: json['id_cliente'] ?? '',
      clienteNombre: '$nombre $apellido'.trim(),
      clienteTelefono: cliente?['num_telefono'],
      clienteEmail: cliente?['email'],
      clienteDireccion: cliente?['direccion'],
      clienteCi: cliente?['ci'],
      idEstado: json['id_estado'] ?? 0,
      estadoOrden: eOrden?['nombre_estado'] ?? 'Desconocido',
      idEstadoPago: json['id_estado_pago'] ?? 0,
      estadoPago: ePago?['nombre_estado'] ?? 'Pendiente',
      fechaOrden: DateTime.parse(json['fecha_orden']),
      fechaEntrega: DateTime.parse(json['fecha_entrega']),
      costoTotal: (json['costo_total'] as num).toDouble(),

      // 👈 Inyectamos el resumen inteligente aquí:
      producto: resumenProductos,

      cantidad: totalCant,
      desgloseTallas: tallasReales,
      imagenModelo: img,
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
  
