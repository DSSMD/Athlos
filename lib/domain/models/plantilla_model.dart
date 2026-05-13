/// Representa una plantilla de prenda del catálogo — el "diseño base" de
/// una prenda específica (ej: "Polera manga corta v1") que puede usarse
/// suelta en una orden, o ser parte de un conjunto vía conjunto_plantilla.
/// Mapea con la tabla plantilla_prenda.
class Plantilla {
  final String idPlantilla;
  final int idTipoPrenda;
  final String? nombreTipoPrenda; // denormalizado del join con tipo_prenda
  final String nombre;
  final String? especificaciones;
  final double?
  precioPlantilla; // nullable hasta que Den agregue la columna en BD
  final int version;
  final bool activo;

  const Plantilla({
    required this.idPlantilla,
    required this.idTipoPrenda,
    this.nombreTipoPrenda,
    required this.nombre,
    this.especificaciones,
    this.precioPlantilla,
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
      precioPlantilla: (json['precio_plantilla'] as num?)?.toDouble(),
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
      'precio_plantilla': precioPlantilla,
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
    double? precioPlantilla,
    int? version,
    bool? activo,
  }) {
    return Plantilla(
      idPlantilla: idPlantilla ?? this.idPlantilla,
      idTipoPrenda: idTipoPrenda ?? this.idTipoPrenda,
      nombreTipoPrenda: nombreTipoPrenda ?? this.nombreTipoPrenda,
      nombre: nombre ?? this.nombre,
      especificaciones: especificaciones ?? this.especificaciones,
      precioPlantilla: precioPlantilla ?? this.precioPlantilla,
      version: version ?? this.version,
      activo: activo ?? this.activo,
    );
  }
}
