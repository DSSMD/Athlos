// ============================================================================
// lib/domain/models/tipo_prenda_model.dart
// ============================================================================
// Catálogo dinámico de tipos de prenda. Viene de la tabla `tipo_prenda` en
// Supabase. NO hardcodear valores — siempre se consulta a la BD.
// Si el equipo agrega/elimina tipos en SQL, el frontend se actualiza
// automáticamente al recargar la app (provider con autoDispose: false).
//
// Mapeo SQL:
// - id_tipo_prenda      (serial PK)  → id
// - nombre_prenda       (varchar)    → nombre
// - descripcion         (text, null) → descripcion
// - categoria_prenda    (varchar 50) → categoria  (default: 'General')
// ============================================================================

class TipoPrendaModel {
  const TipoPrendaModel({
    required this.id,
    required this.nombre,
    required this.categoria,
    this.descripcion,
  });

  final int id;
  final String nombre;

  /// Categoría a la que pertenece el tipo de prenda.
  /// Valores posibles en la BD: 'Superior', 'Inferior', 'Exterior',
  /// 'Accesorio'. Se usa para filtrar el dropdown de tipo de prenda en
  /// el formulario multi-paso (el usuario primero elige categoría, luego
  /// el tipo filtrado por esa categoría).
  final String categoria;

  final String? descripcion;

  // ─── COPYWITH ─────────────────────────────────────────────────────────────

  TipoPrendaModel copyWith({
    int? id,
    String? nombre,
    String? categoria,
    String? descripcion,
  }) {
    return TipoPrendaModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      descripcion: descripcion ?? this.descripcion,
    );
  }

  // ─── SERIALIZACIÓN ────────────────────────────────────────────────────────

  factory TipoPrendaModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id_tipo_prenda'];
    return TipoPrendaModel(
      id: rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0,
      nombre: (json['nombre_prenda'] ?? '') as String,
      categoria: (json['categoria_prenda'] as String?) ?? 'General',
      descripcion: json['descripcion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_tipo_prenda': id,
      'nombre_prenda': nombre,
      'categoria_prenda': categoria,
      if (descripcion != null) 'descripcion': descripcion,
    };
  }

  // ─── EQUALITY (importante para DropdownMenuItem.value) ────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TipoPrendaModel && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'TipoPrendaModel(id: $id, nombre: $nombre, categoria: $categoria)';
}
