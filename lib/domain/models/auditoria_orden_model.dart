class AuditoriaOrdenModel {
  final String idLog;
  final String numOrden;
  final String? idUsuario;
  final String? usuarioNombre;
  final DateTime fechaCambio;
  final String? descripcionDetalle;
  final int? estadoAnteriorId;
  final String? estadoAnteriorNombre;
  final int? estadoNuevoId;
  final String? estadoNuevoNombre;

  AuditoriaOrdenModel({
    required this.idLog,
    required this.numOrden,
    this.idUsuario,
    this.usuarioNombre,
    required this.fechaCambio,
    this.descripcionDetalle,
    this.estadoAnteriorId,
    this.estadoAnteriorNombre,
    this.estadoNuevoId,
    this.estadoNuevoNombre,
  });

  factory AuditoriaOrdenModel.fromJson(Map<String, dynamic> json) {
    // Procesar usuario de profile anidado
    final profile = json['profiles'] as Map<String, dynamic>?;
    final nombre = profile?['nombre'] ?? '';
    final apellido = profile?['apellido'] ?? '';
    final usuarioNombre = '$nombre $apellido'.trim();

    final estadoAnterior = json['estado_anterior'] as Map<String, dynamic>?;
    final estadoNuevo = json['estado_nuevo'] as Map<String, dynamic>?;

    return AuditoriaOrdenModel(
      idLog: json['id_log']?.toString() ?? '',
      numOrden: json['num_orden']?.toString() ?? '',
      idUsuario: json['id_usuario']?.toString(),
      usuarioNombre: usuarioNombre.isEmpty ? 'Sistema / Worker' : usuarioNombre,
      fechaCambio: json['fecha_cambio'] != null
          ? DateTime.parse(json['fecha_cambio'].toString()).toLocal()
          : DateTime.now(),
      descripcionDetalle: json['descripcion_detalle']?.toString(),
      estadoAnteriorId: json['estado_anterior_id'] as int?,
      estadoAnteriorNombre: estadoAnterior?['nombre_estado']?.toString(),
      estadoNuevoId: json['estado_nuevo_id'] as int?,
      estadoNuevoNombre: estadoNuevo?['nombre_estado']?.toString(),
    );
  }
}
