/// Representa un conjunto del catálogo — un paquete de plantillas que
/// se vende como una unidad (ej: "Deportivo" = remera + pantalón + chaqueta).
/// Mapea con la tabla conjunto. La composición interna (qué plantillas lo
/// integran) vive en la tabla conjunto_plantilla y se modela aparte en
/// ComposicionInterna (definida en detalle_orden_model.dart) cuando se
/// fetchea como parte de una orden.
class Conjunto {
  final String idConjunto;
  final String nombre;
  final String? descripcion;
  final double?
  precioConjunto; // nullable hasta que Den agregue la columna en BD
  final bool activo;

  const Conjunto({
    required this.idConjunto,
    required this.nombre,
    this.descripcion,
    this.precioConjunto,
    this.activo = true,
  });

  factory Conjunto.fromJson(Map<String, dynamic> json) {
    return Conjunto(
      idConjunto: json['id_conjunto'] as String,
      nombre: json['nombre'] as String,
      descripcion: json['descripcion'] as String?,
      precioConjunto: (json['precio_conjunto'] as num?)?.toDouble(),
      activo: (json['activo'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_conjunto': idConjunto,
      'nombre': nombre,
      'descripcion': descripcion,
      'precio_conjunto': precioConjunto,
      'activo': activo,
    };
  }

  Conjunto copyWith({
    String? idConjunto,
    String? nombre,
    String? descripcion,
    double? precioConjunto,
    bool? activo,
  }) {
    return Conjunto(
      idConjunto: idConjunto ?? this.idConjunto,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      precioConjunto: precioConjunto ?? this.precioConjunto,
      activo: activo ?? this.activo,
    );
  }
}
