/// Representa una plantilla de prenda del catálogo — el "diseño base" de
/// una prenda específica (ej: "Polera manga corta v1") que puede usarse
/// suelta en una orden, o ser parte de un conjunto vía conjunto_plantilla.
/// Mapea con la tabla plantilla_prenda.
/// Nota: el precio NO se almacena en el catálogo; el vendedor lo ingresa
/// manualmente al crear la orden (se guarda en detalle_orden.precio_unitario).
class Plantilla {
  final String idPlantilla;
  final int idTipoPrenda;
  final String? nombreTipoPrenda;
  final String nombre;
  final String? especificaciones;
  final int version;
  final bool activo;

  const Plantilla({
    required this.idPlantilla,
    required this.idTipoPrenda,
    this.nombreTipoPrenda,
    required this.nombre,
    this.especificaciones,
    this.version = 1,
    this.activo = true,
  });

  factory Plantilla.fromJson(Map<String, dynamic> json) {
    return Plantilla(
      idPlantilla: json['id_plantilla'] as String,
      idTipoPrenda: (json['id_tipo_prenda'] as num).toInt(),
      nombreTipoPrenda: json['tipo_prenda']?['nombre_prenda'] as String?,
      nombre: json['nombre'] as String,
      especificaciones: json['especificaciones'] as String?,
      version: (json['version'] as num?)?.toInt() ?? 1,
      activo: (json['activo'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_plantilla': idPlantilla,
      'id_tipo_prenda': idTipoPrenda,
      'nombre': nombre,
      'especificaciones': especificaciones,
      'version': version,
      'activo': activo,
    };
  }

  Plantilla copyWith({
    String? idPlantilla,
    int? idTipoPrenda,
    String? nombreTipoPrenda,
    String? nombre,
    String? especificaciones,
    int? version,
    bool? activo,
  }) {
    return Plantilla(
      idPlantilla: idPlantilla ?? this.idPlantilla,
      idTipoPrenda: idTipoPrenda ?? this.idTipoPrenda,
      nombreTipoPrenda: nombreTipoPrenda ?? this.nombreTipoPrenda,
      nombre: nombre ?? this.nombre,
      especificaciones: especificaciones ?? this.especificaciones,
      version: version ?? this.version,
      activo: activo ?? this.activo,
    );
  }
}
