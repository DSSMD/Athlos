// ============================================================================
// lib/domain/models/medida_punto_model.dart
// ============================================================================
// Modelo de un punto de medida del cuadro de medidas (Paso 2 del form).
// Cada MedidaPunto representa una FILA de la tabla del Paso 2:
// - "Ancho total" → S=50, M=52, L=54, XL=56, XXL=58
// - "Largo manga" → S=60, M=62, ...
//
// Las columnas de la tabla son las TallaPrenda seleccionadas en Paso 2.
//
// DECISIÓN: valores en centímetros únicamente. RAZÓN: estándar textil,
// simplifica la UI. CAMBIAR: agregar campo `unidad` si se requiere otra
// unidad (pulgadas, metros).
// ============================================================================

import 'plantilla_model.dart' show TallaPrenda;

// DECISIÓN: Map<TallaPrenda, double> en lugar de List<double> indexada.
// RAZÓN: si el usuario deselecciona una talla, no se pierden los datos de
// las otras (más robusto que un array indexado). También permite agregar
// nuevas tallas sin reordenar.
class MedidaPunto {
  const MedidaPunto({
    required this.id,
    required this.nombre,
    required this.valoresPorTalla,
  });

  final String id; // id local del punto, ej: '1234567890123'
  final String nombre; // ej: "Ancho total"
  final Map<TallaPrenda, double> valoresPorTalla; // valores en CENTÍMETROS

  // ─── COPYWITH ─────────────────────────────────────────────────────────────

  MedidaPunto copyWith({
    String? id,
    String? nombre,
    Map<TallaPrenda, double>? valoresPorTalla,
  }) {
    return MedidaPunto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      valoresPorTalla: valoresPorTalla ?? this.valoresPorTalla,
    );
  }

  // ─── SERIALIZACIÓN ────────────────────────────────────────────────────────

  factory MedidaPunto.fromJson(Map<String, dynamic> json) {
    final rawValores =
        (json['valores_por_talla'] as Map?) ?? const <String, dynamic>{};
    final valores = <TallaPrenda, double>{};
    rawValores.forEach((key, value) {
      final talla = TallaPrenda.fromString(key?.toString());
      if (talla == null) return;
      final n = (value is num) ? value.toDouble() : null;
      if (n != null) valores[talla] = n;
    });

    return MedidaPunto(
      id: json['id'].toString(),
      nombre: (json['nombre'] ?? '') as String,
      valoresPorTalla: valores,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'valores_por_talla': {
        for (final entry in valoresPorTalla.entries)
          entry.key.name: entry.value,
      },
    };
  }
}
