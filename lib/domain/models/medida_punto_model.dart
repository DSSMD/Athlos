// ============================================================================
// lib/domain/models/medida_punto_model.dart
// ============================================================================
// Modelo de un punto de medida del cuadro de medidas (Paso 2 del form).
// Cada MedidaPunto representa una FILA de la tabla del Paso 2:
// - "Ancho total" → {idTalla 1: 50, idTalla 2: 52, idTalla 3: 54, ...}
//
// Las columnas de la tabla son IDs de tallas del catálogo `tallas`.
//
// DECISIÓN: valores en centímetros únicamente. RAZÓN: estándar textil,
// simplifica la UI. CAMBIAR: agregar campo `unidad` si se requiere otra
// unidad (pulgadas, metros).
//
// IMPORTANTE — diferencia con la tabla SQL:
// En la app, una MedidaPunto agrupa N tallas en un objeto único. En SQL,
// la tabla `medida_ficha` tiene una fila por cada (talla, medida). Los
// helpers `fromFilasSQL` / `aFilasSQL` hacen la conversión cuando el
// service carga o guarda medidas.
// ============================================================================

import 'talla_model.dart';

// DECISIÓN: Map<int, double> en lugar de List<double> indexada.
// RAZÓN: si el usuario deselecciona una talla, no se pierden los datos de
// las otras (más robusto que un array indexado). También permite agregar
// nuevas tallas sin reordenar.
class MedidaPunto {
  const MedidaPunto({
    required this.id,
    required this.nombre,
    required this.valoresPorTalla,
  });

  final String
  id; // id local — no se persiste a SQL (medida_ficha tiene UUIDs propios)
  final String nombre; // ej: "Ancho total"
  final Map<int, double> valoresPorTalla; // id_talla → valor en cm

  // ─── COPYWITH ─────────────────────────────────────────────────────────────

  MedidaPunto copyWith({
    String? id,
    String? nombre,
    Map<int, double>? valoresPorTalla,
  }) {
    return MedidaPunto(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      valoresPorTalla: valoresPorTalla ?? this.valoresPorTalla,
    );
  }

  // ─── SERIALIZACIÓN JSON LOCAL ─────────────────────────────────────────────
  // Útil cuando se serializa el form en memoria o se cachea localmente.
  // NO es el formato directo de SQL (que es una fila por valor — ver
  // fromFilasSQL / aFilasSQL).

  factory MedidaPunto.fromJson(Map<String, dynamic> json) {
    final rawValores =
        (json['valores_por_talla'] as Map?) ?? const <String, dynamic>{};
    final valores = <int, double>{};
    rawValores.forEach((key, value) {
      final idTalla = int.tryParse(key?.toString() ?? '');
      if (idTalla == null) return;
      final n = (value is num) ? value.toDouble() : null;
      if (n != null) valores[idTalla] = n;
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
          entry.key.toString(): entry.value,
      },
    };
  }

  // ─── CONVERSIÓN A/DESDE FILAS SQL (medida_ficha) ──────────────────────────

  /// Agrupa N filas de `medida_ficha` (todas con el mismo nombre_medida) en
  /// una sola MedidaPunto.
  ///
  /// Cada fila tiene la forma:
  /// `{id_plantilla, id_talla, nombre_medida, valor}`.
  ///
  /// El `id` local del MedidaPunto se genera combinando idPlantilla y el
  /// nombre — útil para tracking dentro del form, NO se guarda en SQL.
  factory MedidaPunto.fromFilasSQL({
    required String idPlantilla,
    required String nombreMedida,
    required List<Map<String, dynamic>> filas,
  }) {
    final valores = <int, double>{};
    for (final fila in filas) {
      final idTalla = fila['id_talla'] is int
          ? fila['id_talla'] as int
          : int.tryParse(fila['id_talla']?.toString() ?? '');
      final valor = (fila['valor'] as num?)?.toDouble();
      if (idTalla != null && valor != null) {
        valores[idTalla] = valor;
      }
    }
    return MedidaPunto(
      id: '${idPlantilla}_$nombreMedida',
      nombre: nombreMedida,
      valoresPorTalla: valores,
    );
  }

  /// Genera N mapas listos para INSERT en `medida_ficha` — uno por cada
  /// entrada de valoresPorTalla. El `id_medida` lo genera la BD (uuid).
  List<Map<String, dynamic>> aFilasSQL(String idPlantilla) {
    return [
      for (final entry in valoresPorTalla.entries)
        {
          'id_plantilla': idPlantilla,
          'id_talla': entry.key,
          'nombre_medida': nombre,
          'valor': entry.value,
        },
    ];
  }

  // ─── HELPERS DE PRESENTACIÓN ──────────────────────────────────────────────

  /// Devuelve el valor formateado para una talla específica, o `'—'` si
  /// no hay valor cargado para esa talla. El catálogo se usa para validar
  /// que la talla pedida exista; si no, también retorna `'—'`.
  String valorParaTalla(int idTalla, List<TallaModel> catalogo) {
    final existe = catalogo.any((t) => t.id == idTalla);
    if (!existe) return '—';
    final valor = valoresPorTalla[idTalla];
    if (valor == null) return '—';
    return valor.toStringAsFixed(1);
  }
}
