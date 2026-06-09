// ============================================================================
// lib/domain/models/material_plantilla_model.dart
// ============================================================================
// Modelo de un material requerido por una plantilla (Paso 3 del form).
// Cada MaterialPlantilla representa una FILA de `receta_material`:
// - Insumo "Tela algodón blanco" — cantidad: 1.5
// - Insumo "Hilo blanco #100"   — cantidad: 0.1
//
// La UNIDAD (metros, conos, unidades) NO se guarda acá:
// - Se obtiene del catálogo de insumos al renderizar.
// - Esto evita duplicación e inconsistencias si cambia la unidad del insumo.
//
// DECISIÓN: solo cantidad como dato propio. RAZÓN: la unidad pertenece al
// insumo, no a la receta. CAMBIAR: si las recetas necesitan unidad propia
// (ej: convertir m² a m), agregar campo `unidad` y conversión en runtime.
//
// Mapeo SQL (receta_material):
// - id_receta          serial PK → id (String)
// - id_plantilla       uuid FK   → se inyecta al insertar (no es propiedad del modelo)
// - id_insumo          uuid FK   → idInsumo
// - cantidad_requerida numeric   → cantidad
//
// IMPORTANTE: existe trigger en receta_material que bloquea inserts con
// insumos inactivos. El service traduce ese error a un mensaje amigable.
// ============================================================================

class MaterialPlantilla {
  const MaterialPlantilla({
    required this.id,
    required this.idInsumo,
    required this.cantidad,
  });

  final String id; // id_receta del SQL
  final String idInsumo; // FK a insumo
  final double cantidad;

  // ─── COPYWITH ─────────────────────────────────────────────────────────────

  MaterialPlantilla copyWith({String? id, String? idInsumo, double? cantidad}) {
    return MaterialPlantilla(
      id: id ?? this.id,
      idInsumo: idInsumo ?? this.idInsumo,
      cantidad: cantidad ?? this.cantidad,
    );
  }

  // ─── SERIALIZACIÓN ────────────────────────────────────────────────────────

  factory MaterialPlantilla.fromJson(Map<String, dynamic> json) {
    return MaterialPlantilla(
      id: (json['id_receta'] ?? '').toString(),
      idInsumo: (json['id_insumo'] ?? '').toString(),
      cantidad: (json['cantidad_requerida'] as num?)?.toDouble() ?? 0,
    );
  }

  /// Solo los campos requeridos para INSERT en `receta_material`. El
  /// `id_plantilla` se inyecta desde el caller (el service ya conoce la
  /// plantilla a la que pertenece). `id_receta` lo genera el SERIAL.
  Map<String, dynamic> toJson() {
    return {'id_insumo': idInsumo, 'cantidad_requerida': cantidad};
  }
}
