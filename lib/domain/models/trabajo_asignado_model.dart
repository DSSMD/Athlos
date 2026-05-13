// lib/domain/models/trabajo_asignado_model.dart

class TrabajoAsignadoModel {
  final String loteId;
  final String ordenId;
  final String cliente;
  final String estado; // 'PENDIENTE', 'EN PROCESO', 'TERMINADO'
  final DateTime fechaAsignacion;
  final String actividad; // Ej: "Cortar tela", "Costura de mangas"
  final int cantidad;
  final List<String> tallas;
  final String instrucciones;

  TrabajoAsignadoModel({
    required this.loteId,
    required this.ordenId,
    required this.cliente,
    required this.estado,
    required this.fechaAsignacion,
    required this.actividad,
    required this.cantidad,
    required this.tallas,
    required this.instrucciones,
  });

  /// Crea una copia del modelo con algunos campos cambiados.
  /// Muy útil para actualizar el estado de PENDIENTE a EN PROCESO localmente.
  TrabajoAsignadoModel copyWith({
    String? estado,
    String? actividad,
  }) {
    return TrabajoAsignadoModel(
      loteId: loteId,
      ordenId: ordenId,
      cliente: cliente,
      estado: estado ?? this.estado,
      fechaAsignacion: fechaAsignacion,
      actividad: actividad ?? this.actividad,
      cantidad: cantidad,
      tallas: tallas,
      instrucciones: instrucciones,
    );
  }

  /// TODO: BACKEND - Mapeo de base de datos (Supabase/FastAPI) a objeto Flutter
  factory TrabajoAsignadoModel.fromJson(Map<String, dynamic> json) {
    return TrabajoAsignadoModel(
      loteId: json['lote_id'] ?? '',
      ordenId: json['orden_id'] ?? '',
      cliente: json['cliente'] ?? 'Sin cliente',
      estado: json['estado'] ?? 'PENDIENTE',
      fechaAsignacion: json['fecha_asignacion'] != null 
          ? DateTime.parse(json['fecha_asignacion']) 
          : DateTime.now(),
      actividad: json['actividad'] ?? '',
      cantidad: json['cantidad'] ?? 0,
      tallas: List<String>.from(json['tallas'] ?? []),
      instrucciones: json['instrucciones'] ?? 'Sin instrucciones adicionales.',
    );
  }

  /// TODO: BACKEND - Convertir el objeto a JSON para enviarlo al servidor
  Map<String, dynamic> toJson() {
    return {
      'lote_id': loteId,
      'estado': estado,
      'actividad': actividad,
      // No solemos enviar todos los campos de vuelta, 
      // solo los que el trabajador puede cambiar (como el estado).
    };
  }
}