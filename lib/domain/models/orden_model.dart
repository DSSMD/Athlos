class OrdenModel {
  final String numOrden;
  final String idCliente;
  final DateTime fechaOrden;
  final DateTime fechaEntrega;
  final int idEstado;
  final int? idEstadoPago; // Puede venir nulo según tu BD
  final double costoTotal;

  OrdenModel({
    required this.numOrden,
    required this.idCliente,
    required this.fechaOrden,
    required this.fechaEntrega,
    required this.idEstado,
    this.idEstadoPago,
    required this.costoTotal,
  });

  factory OrdenModel.fromJson(Map<String, dynamic> json) {
    return OrdenModel(
      numOrden: json['num_orden'] ?? '',
      idCliente: json['id_cliente'] ?? '',
      fechaOrden: json['fecha_orden'] != null
          ? DateTime.parse(json['fecha_orden'])
          : DateTime.now(),
      fechaEntrega: json['fecha_entrega'] != null
          ? DateTime.parse(json['fecha_entrega'])
          : DateTime.now(),
      idEstado: json['id_estado'] ?? 1,
      idEstadoPago: json['id_estado_pago'],
      costoTotal: json['costo_total'] != null
          ? (json['costo_total'] as num).toDouble()
          : 0.0,
    );
  }
}
