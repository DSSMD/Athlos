// ============================================================================
// lib/domain/models/talla_model.dart
// ============================================================================
// Catálogo dinámico de tallas. Viene de la tabla `tallas` en Supabase.
// NO hardcodear valores — siempre se consulta a la BD.
//
// Mapeo SQL:
// - id_talla       (serial PK)  → id
// - nombre_talla   (varchar)    → nombre  (ej: "S", "M", "L", "XL", "2", "4")
// - descripcion    (text, null) → descripcion
// ============================================================================

class TallaModel {
  const TallaModel({required this.id, required this.nombre, this.descripcion});

  final int id;
  final String nombre;
  final String? descripcion;

  // ─── COPYWITH ─────────────────────────────────────────────────────────────

  TallaModel copyWith({int? id, String? nombre, String? descripcion}) {
    return TallaModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
    );
  }

  // ─── SERIALIZACIÓN ────────────────────────────────────────────────────────

  factory TallaModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id_talla'];
    return TallaModel(
      id: rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0,
      nombre: (json['nombre_talla'] ?? '') as String,
      descripcion: json['descripcion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_talla': id,
      'nombre_talla': nombre,
      if (descripcion != null) 'descripcion': descripcion,
    };
  }

  // ─── EQUALITY (importante para chips multi-select) ────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is TallaModel && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TallaModel(id: $id, nombre: $nombre)';
}
