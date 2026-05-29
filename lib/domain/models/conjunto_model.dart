// ============================================================================
// lib/domain/models/conjunto_model.dart
// ============================================================================
// Modelos del módulo Conjuntos.
//
// Contiene dos clases en un solo archivo porque siempre se usan juntas:
//   - ConjuntoPlantillaModel : fila de la tabla `conjunto_plantilla`
//     (relación N:M entre conjunto y plantilla_prenda).
//   - ConjuntoModel          : fila de la tabla `conjunto`, con su lista
//     de ConjuntoPlantillaModel embebida.
//
// DECISIÓN: precio_conjunto se calcula automáticamente (getter `precioTotal`)
// sumando precio_plantilla × cantidad_por_conjunto de cada ítem.
// El campo `precio_conjunto` en BD se persiste al guardar, pero en UI
// siempre se muestra el valor calculado.
//
// Mapeo SQL (conjunto):
//   id_conjunto     uuid PK  → id
//   nombre          varchar  → nombre
//   descripcion     text     → descripcion
//   activo          bool     → activo
//   created_at      ts       → fechaCreacion
//   precio_conjunto numeric  → precio (guardado en BD, calculado en UI)
//
// Mapeo SQL (conjunto_plantilla):
//   id_cp               uuid PK  → id
//   id_conjunto         uuid FK  → conjuntoId
//   id_plantilla        uuid FK  → plantillaId
//   cantidad_por_conjunto int    → cantidad
//   (join a plantilla_prenda)
//     nombre            text     → nombrePlantilla
//     precio_plantilla  numeric  → precioPlantilla
// ============================================================================

// ─── CONJUNTO PLANTILLA MODEL ────────────────────────────────────────────────

class ConjuntoPlantillaModel {
  const ConjuntoPlantillaModel({
    required this.id,
    required this.conjuntoId,
    required this.plantillaId,
    required this.nombrePlantilla,
    required this.cantidad,
    required this.precioPlantilla,
  });

  final String id;           // id_cp (PK de la tabla intermedia)
  final String conjuntoId;   // id_conjunto (FK)
  final String plantillaId;  // id_plantilla (FK)
  final String nombrePlantilla; // nombre de plantilla_prenda (join)
  final int cantidad;            // cantidad_por_conjunto
  final double precioPlantilla;  // precio_plantilla (join)

  /// Subtotal de este ítem: precio_plantilla × cantidad_por_conjunto.
  double get subtotal => precioPlantilla * cantidad;

  factory ConjuntoPlantillaModel.fromJson(Map<String, dynamic> json) {
    // El campo json viene del join:
    // conjunto_plantilla ( *, plantilla_prenda ( nombre, precio_plantilla ) )
    final plantillaData = json['plantilla_prenda'] as Map<String, dynamic>?;

    return ConjuntoPlantillaModel(
      id: (json['id_cp'] ?? '').toString(),
      conjuntoId: (json['id_conjunto'] ?? '').toString(),
      plantillaId: (json['id_plantilla'] ?? '').toString(),
      cantidad: (json['cantidad_por_conjunto'] as num?)?.toInt() ?? 1,
      nombrePlantilla: (plantillaData?['nombre'] as String?) ?? 'Desconocido',
      precioPlantilla:
          double.tryParse(
            plantillaData?['precio_plantilla']?.toString() ?? '0',
          ) ??
          0.0,
    );
  }

  /// Para insertar en `conjunto_plantilla` (sin id_cp ni id_conjunto — los
  /// provee la BD y el service respectivamente).
  Map<String, dynamic> toInsertJson(String idConjunto) {
    return {
      'id_conjunto': idConjunto,
      'id_plantilla': plantillaId,
      'cantidad_por_conjunto': cantidad,
    };
  }

  ConjuntoPlantillaModel copyWith({
    String? id,
    String? conjuntoId,
    String? plantillaId,
    String? nombrePlantilla,
    int? cantidad,
    double? precioPlantilla,
  }) {
    return ConjuntoPlantillaModel(
      id: id ?? this.id,
      conjuntoId: conjuntoId ?? this.conjuntoId,
      plantillaId: plantillaId ?? this.plantillaId,
      nombrePlantilla: nombrePlantilla ?? this.nombrePlantilla,
      cantidad: cantidad ?? this.cantidad,
      precioPlantilla: precioPlantilla ?? this.precioPlantilla,
    );
  }
}

// ─── CONJUNTO MODEL ───────────────────────────────────────────────────────────

class ConjuntoModel {
  const ConjuntoModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.fechaCreacion,
    this.activo = true,
    this.plantillas = const [],
  });

  final String id;
  final String nombre;
  final String descripcion;
  final bool activo;
  final DateTime fechaCreacion;

  /// Plantillas que componen este conjunto.
  /// Se cargan vía join: conjunto_plantilla → plantilla_prenda.
  final List<ConjuntoPlantillaModel> plantillas;

  /// Precio total calculado: suma de (precio_plantilla × cantidad) de cada ítem.
  /// Este valor es el que se persiste en `precio_conjunto` al guardar.
  double get precioTotal =>
      plantillas.fold(0.0, (sum, item) => sum + item.subtotal);

  // ─── SERIALIZACIÓN ────────────────────────────────────────────────────────

  factory ConjuntoModel.fromJson(Map<String, dynamic> json) {
    final rawPlantillas = json['conjunto_plantilla'] as List?;
    return ConjuntoModel(
      id: (json['id_conjunto'] ?? '').toString(),
      nombre: (json['nombre'] as String?) ?? '',
      descripcion: (json['descripcion'] as String?) ?? '',
      activo: (json['activo'] as bool?) ?? true,
      fechaCreacion:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      plantillas:
          rawPlantillas
              ?.map(
                (x) => ConjuntoPlantillaModel.fromJson(
                  x as Map<String, dynamic>,
                ),
              )
              .toList() ??
          const [],
    );
  }

  /// Solo campos directos de `conjunto`. El precio se calcula y se pasa
  /// explícitamente desde el service al momento de insertar/actualizar.
  Map<String, dynamic> toInsertJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'activo': activo,
      'precio_conjunto': precioTotal,
    };
  }

  // ─── COPYWITH ─────────────────────────────────────────────────────────────

  ConjuntoModel copyWith({
    String? id,
    String? nombre,
    String? descripcion,
    bool? activo,
    DateTime? fechaCreacion,
    List<ConjuntoPlantillaModel>? plantillas,
  }) {
    return ConjuntoModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      activo: activo ?? this.activo,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      plantillas: plantillas ?? this.plantillas,
    );
  }
}
