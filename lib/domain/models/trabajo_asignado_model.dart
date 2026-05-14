// lib/domain/models/trabajo_asignado_model.dart

// lib/domain/models/trabajo_asignado_model.dart

class TrabajoAsignadoModel {
  final String idAsignacion; // Aquí guardaremos el string de IDs combinados
  final String loteId;
  final String cliente;
  final String estado;
  final int cantidad;
  final String tallas;
  final String actividad;
  final String instrucciones;
  final DateTime fechaAsignacion;

  TrabajoAsignadoModel({
    required this.idAsignacion,
    required this.loteId,
    required this.cliente,
    required this.estado,
    required this.cantidad,
    required this.tallas,
    required this.actividad,
    required this.instrucciones,
    required this.fechaAsignacion,
  });

  factory TrabajoAsignadoModel.fromJson(Map<String, dynamic> json) {
    return TrabajoAsignadoModel(
      // Mapeamos el campo combinado ids_asignaciones
      idAsignacion: json['ids_asignaciones'] ?? '',
      loteId: json['lote_id'] ?? '',
      cliente: json['cliente'] ?? '',
      estado: json['estado'] ?? '',
      cantidad: (json['cantidad'] as num?)?.toInt() ?? 0,
      tallas: json['tallas'] ?? '',
      actividad: json['actividad'] ?? '',
      instrucciones: json['instrucciones'] ?? '',
      fechaAsignacion: json['fecha_asignacion'] != null
          ? DateTime.parse(json['fecha_asignacion'])
          : DateTime.now(),
    );
  }
}
