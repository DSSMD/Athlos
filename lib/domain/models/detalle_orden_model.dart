/// Discriminador del tipo de ítem dentro de un detalle_orden.
/// Un detalle_orden referencia o un conjunto, o una plantilla suelta.
enum TipoItem {
  conjunto,
  plantilla;

  /// Convierte el string del JSON ('conjunto' / 'plantilla') al enum.
  static TipoItem fromString(String value) {
    return TipoItem.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('TipoItem desconocido: $value'),
    );
  }

  /// Devuelve el nombre del enum para serializar al JSON.
  String toJson() => name;
}

/// Una talla específica dentro de un detalle_orden.
/// Mapea 1:1 con la tabla detalle_orden_talla.
class DetalleOrdenTalla {
  final String idDesglose;
  final int idTalla;
  final String nombreTalla; // denormalizado, viene del join con la tabla tallas
  final int cantidad;

  const DetalleOrdenTalla({
    required this.idDesglose,
    required this.idTalla,
    required this.nombreTalla,
    required this.cantidad,
  });

  factory DetalleOrdenTalla.fromJson(Map<String, dynamic> json) {
    return DetalleOrdenTalla(
      idDesglose: json['id_desglose'] as String,
      idTalla: (json['id_talla'] as num).toInt(),
      nombreTalla: (json['tallas']?['nombre_talla'] as String?) ?? '?',
      cantidad: (json['cantidad'] as num).toInt(),
    );
  }

  /// Para INSERT en detalle_orden_talla. id_detalle se setea en el service
  /// al momento de insertar (no vive en este modelo).
  Map<String, dynamic> toJson() {
    return {'id_talla': idTalla, 'cantidad': cantidad};
  }

  DetalleOrdenTalla copyWith({
    String? idDesglose,
    int? idTalla,
    String? nombreTalla,
    int? cantidad,
  }) {
    return DetalleOrdenTalla(
      idDesglose: idDesglose ?? this.idDesglose,
      idTalla: idTalla ?? this.idTalla,
      nombreTalla: nombreTalla ?? this.nombreTalla,
      cantidad: cantidad ?? this.cantidad,
    );
  }
}

/// Una plantilla que compone un conjunto. Solo aparece en lecturas (no se
/// escribe al crear orden), y solo cuando el detalle_orden es de tipo conjunto.
/// Viene de la tabla conjunto_plantilla.
class ComposicionInterna {
  final String idPlantilla;
  final String
  nombrePlantilla; // denormalizado, viene del join con plantilla_prenda
  final int cantidadPorConjunto;

  const ComposicionInterna({
    required this.idPlantilla,
    required this.nombrePlantilla,
    required this.cantidadPorConjunto,
  });

  factory ComposicionInterna.fromJson(Map<String, dynamic> json) {
    return ComposicionInterna(
      idPlantilla: json['id_plantilla'] as String,
      nombrePlantilla: (json['plantilla_prenda']?['nombre'] as String?) ?? '?',
      cantidadPorConjunto: (json['cantidad_por_conjunto'] as num).toInt(),
    );
  }
}

/// Un ítem dentro de una orden. Cada detalle_orden representa o un conjunto
/// completo, o una plantilla suelta. Mapea 1:1 con la tabla detalle_orden.
class DetalleOrden {
  final String idDetalle;
  final TipoItem tipoItem;
  final String? idConjunto; // poblado si tipoItem == conjunto
  final String? idPlantilla; // poblado si tipoItem == plantilla
  final String nombreItem; // denormalizado para display
  final int cantidadTotal;
  final double
  precioUnitario; // snapshot del precio al momento de crear la orden
  final double subtotal;
  final List<DetalleOrdenTalla> tallas;
  final List<ComposicionInterna>?
  composicionInterna; // solo conjuntos, solo lecturas

  const DetalleOrden({
    required this.idDetalle,
    required this.tipoItem,
    this.idConjunto,
    this.idPlantilla,
    required this.nombreItem,
    required this.cantidadTotal,
    required this.precioUnitario,
    required this.subtotal,
    required this.tallas,
    this.composicionInterna,
  });

  factory DetalleOrden.fromJson(Map<String, dynamic> json) {
    final idConjunto = json['id_conjunto'] as String?;
    final idPlantilla = json['id_plantilla'] as String?;

    // Discriminador derivado: si hay id_conjunto, es conjunto; si no, plantilla.
    final tipoItem = idConjunto != null
        ? TipoItem.conjunto
        : TipoItem.plantilla;

    // Nombre denormalizado: viene del join con conjunto o plantilla_prenda
    // según el tipo de ítem.
    final nombreItem = tipoItem == TipoItem.conjunto
        ? (json['conjunto']?['nombre'] as String?) ?? 'Conjunto sin nombre'
        : (json['plantilla_prenda']?['nombre'] as String?) ??
              'Plantilla sin nombre';

    final tallasRaw = json['detalle_orden_talla'] as List<dynamic>? ?? [];
    final tallas = tallasRaw
        .map((t) => DetalleOrdenTalla.fromJson(t as Map<String, dynamic>))
        .toList();

    // composicion_interna solo se incluye en queries que pidan la composición
    // del conjunto (típicamente la query de detalle, no la de lista).
    List<ComposicionInterna>? composicion;
    if (tipoItem == TipoItem.conjunto &&
        json['conjunto']?['conjunto_plantilla'] != null) {
      composicion = (json['conjunto']['conjunto_plantilla'] as List<dynamic>)
          .map((c) => ComposicionInterna.fromJson(c as Map<String, dynamic>))
          .toList();
    }

    return DetalleOrden(
      idDetalle: json['id_detalle'] as String,
      tipoItem: tipoItem,
      idConjunto: idConjunto,
      idPlantilla: idPlantilla,
      nombreItem: nombreItem,
      cantidadTotal: (json['cantidad_total'] as num).toInt(),
      precioUnitario: (json['precio_unitario'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      tallas: tallas,
      composicionInterna: composicion,
    );
  }

  /// Para INSERT en detalle_orden. num_orden se agrega en el service al
  /// momento de insertar (no vive en este modelo). Las tallas se insertan
  /// aparte en detalle_orden_talla; composicion_interna es read-only.
  Map<String, dynamic> toJson() {
    return {
      'id_conjunto': idConjunto,
      'id_plantilla': idPlantilla,
      'cantidad_total': cantidadTotal,
      'precio_unitario': precioUnitario,
      'subtotal': subtotal,
    };
  }

  DetalleOrden copyWith({
    String? idDetalle,
    TipoItem? tipoItem,
    String? idConjunto,
    String? idPlantilla,
    String? nombreItem,
    int? cantidadTotal,
    double? precioUnitario,
    double? subtotal,
    List<DetalleOrdenTalla>? tallas,
    List<ComposicionInterna>? composicionInterna,
  }) {
    return DetalleOrden(
      idDetalle: idDetalle ?? this.idDetalle,
      tipoItem: tipoItem ?? this.tipoItem,
      idConjunto: idConjunto ?? this.idConjunto,
      idPlantilla: idPlantilla ?? this.idPlantilla,
      nombreItem: nombreItem ?? this.nombreItem,
      cantidadTotal: cantidadTotal ?? this.cantidadTotal,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      subtotal: subtotal ?? this.subtotal,
      tallas: tallas ?? this.tallas,
      composicionInterna: composicionInterna ?? this.composicionInterna,
    );
  }
}
