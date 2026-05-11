// ============================================================================
// lib/domain/models/insumo_model.dart
// ============================================================================
// Catálogo dinámico de insumos del inventario. Viene de la tabla `insumo`
// en Supabase con join a `unidad_medida` para obtener la abreviatura.
//
// Se usa en el Paso 3 del form de Plantillas (Receta de Materiales) para
// poblar el dropdown de insumos y resolver la unidad de cada material.
// También en el Paso 4 (Resumen) para mostrar nombres reales.
//
// Mapeo SQL:
// - id_insumo (uuid PK)               → id
// - nombre   (text)                   → nombre
// - activo   (bool)                   → activo
// - unidad_medida (FK).abreviatura    → unidad (ej "m", "kg", "u")
//
// El JOIN se hace en la query del service:
//   .select('id_insumo, nombre, activo, unidad_medida(abreviatura)')
// y Supabase devuelve { ..., 'unidad_medida': { 'abreviatura': 'm' } }.
// ============================================================================

class InsumoModel {
  const InsumoModel({
    required this.id,
    required this.nombre,
    this.unidad = '',
    this.activo = true,
  });

  final String id;
  final String nombre;
  final String unidad; // abreviatura del catálogo unidad_medida
  final bool activo;

  // ─── SERIALIZACIÓN ────────────────────────────────────────────────────────

  factory InsumoModel.fromJson(Map<String, dynamic> json) {
    var unidad = '';
    final um = json['unidad_medida'];
    if (um is Map) {
      unidad = (um['abreviatura'] ?? '').toString();
    }
    return InsumoModel(
      id: (json['id_insumo'] ?? '').toString(),
      nombre: (json['nombre'] ?? '') as String,
      unidad: unidad,
      activo: (json['activo'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id_insumo': id, 'nombre': nombre, 'activo': activo};
  }

  // ─── EQUALITY (importante para DropdownMenuItem.value) ────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is InsumoModel && other.id == id);

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'InsumoModel(id: $id, nombre: $nombre, unidad: $unidad)';
}
