// ============================================================================
// lib/domain/models/material_plantilla_model.dart
// ============================================================================
// Modelo de un material requerido por una plantilla (Paso 3 del form).
// Cada MaterialPlantilla representa una FILA de la receta:
// - Insumo "Tela algodón blanco" — cantidad: 1.5
// - Insumo "Hilo blanco #100" — cantidad: 0.1
//
// La UNIDAD (metros, conos, unidades) NO se guarda acá:
// - Se obtiene del InventarioItemModel referenciado por idInsumo
// - Esto evita duplicación e inconsistencias si cambia la unidad del insumo
//
// DECISIÓN: solo cantidad como dato propio. RAZÓN: la unidad pertenece al
// insumo, no a la receta. CAMBIAR: si las recetas necesitan unidad propia
// (ej: convertir m² a m), agregar campo `unidad` y conversión en runtime.
// ============================================================================

class MaterialPlantilla {
  const MaterialPlantilla({
    required this.id,
    required this.idInsumo,
    required this.cantidad,
  });

  final String id; // id local del registro material-plantilla
  final String idInsumo; // referencia a InventarioItemModel.id
  final double cantidad;

  // ─── COPYWITH ─────────────────────────────────────────────────────────────

  MaterialPlantilla copyWith({
    String? id,
    String? idInsumo,
    double? cantidad,
  }) {
    return MaterialPlantilla(
      id: id ?? this.id,
      idInsumo: idInsumo ?? this.idInsumo,
      cantidad: cantidad ?? this.cantidad,
    );
  }

  // ─── SERIALIZACIÓN ────────────────────────────────────────────────────────

  factory MaterialPlantilla.fromJson(Map<String, dynamic> json) {
    return MaterialPlantilla(
      id: json['id'].toString(),
      idInsumo: json['id_insumo'].toString(),
      cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'id_insumo': idInsumo, 'cantidad': cantidad};
  }
}
