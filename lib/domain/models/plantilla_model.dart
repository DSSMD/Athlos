// ============================================================================
// lib/domain/models/plantilla_model.dart
// ============================================================================
// Modelo inmutable de una Plantilla de prenda.
//
// Catálogos dinámicos: el modelo NO contiene enums hardcoded. Los tipos de
// prenda y las tallas viven en SQL (tipo_prenda, tallas) y se referencian
// por `idTipoPrenda` (int) y `tallasSeleccionadas` (List<int>).
//
// Helpers de presentación:
// - nombreTipoPrenda(catalogo): resuelve el nombre del tipo desde el
//   catálogo cargado. Si el tipo fue eliminado de la BD, devuelve
//   "Tipo no disponible".
//
// Mapeo SQL (plantilla_prenda):
// - id_plantilla   uuid PK       → id (String)
// - id_tipo_prenda int FK        → idTipoPrenda
// - nombre         text          → nombre
// - especificaciones text        → especificaciones
// - version        int           → version
// - activo         bool          → activa
// - created_at     timestamp     → createdAt
//
// tallasSeleccionadas, medidas y materiales se cargan de tablas hijas
// (medida_ficha, receta_material) y por defecto son [] cuando se construye
// desde una fila de plantilla_prenda sola.
// ============================================================================

import 'material_plantilla_model.dart';
import 'medida_punto_model.dart';
import 'tipo_prenda_model.dart';

// DECISIÓN: medidas, materiales y tallasSeleccionadas son listas, no Maps.
// RAZÓN: el orden importa para la UI (orden en que el usuario las agregó).
// CAMBIAR: si se necesita acceso por id, usar helpers `firstWhere` en runtime.
class PlantillaModel {
  const PlantillaModel({
    required this.id,
    required this.nombre,
    required this.idTipoPrenda,
    required this.version,
    required this.createdAt,
    this.activa = true,
    this.especificaciones = '',
    this.tallasSeleccionadas = const [],
    this.medidas = const [],
    this.materiales = const [],
  });

  final String id; // uuid
  final String nombre;
  final int idTipoPrenda; // FK tipo_prenda.id_tipo_prenda
  final String especificaciones;
  final int version;
  final bool activa;
  final DateTime createdAt;

  // Hijas — se cargan en queries separadas (medida_ficha, receta_material).
  final List<int> tallasSeleccionadas; // ids de tallas
  final List<MedidaPunto> medidas;
  final List<MaterialPlantilla> materiales;

  // ─── COPYWITH ─────────────────────────────────────────────────────────────

  PlantillaModel copyWith({
    String? id,
    String? nombre,
    int? idTipoPrenda,
    String? especificaciones,
    int? version,
    bool? activa,
    DateTime? createdAt,
    List<int>? tallasSeleccionadas,
    List<MedidaPunto>? medidas,
    List<MaterialPlantilla>? materiales,
  }) {
    return PlantillaModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      idTipoPrenda: idTipoPrenda ?? this.idTipoPrenda,
      especificaciones: especificaciones ?? this.especificaciones,
      version: version ?? this.version,
      activa: activa ?? this.activa,
      createdAt: createdAt ?? this.createdAt,
      tallasSeleccionadas: tallasSeleccionadas ?? this.tallasSeleccionadas,
      medidas: medidas ?? this.medidas,
      materiales: materiales ?? this.materiales,
    );
  }

  // ─── SERIALIZACIÓN ────────────────────────────────────────────────────────

  /// Construye un PlantillaModel desde una fila de `plantilla_prenda`.
  /// Las hijas (medidas, materiales, tallas) quedan vacías — se cargan
  /// por separado vía `obtenerPlantillaCompleta(id)`.
  factory PlantillaModel.fromJson(Map<String, dynamic> json) {
    final rawTipo = json['id_tipo_prenda'];
    final rawVersion = json['version'];

    return PlantillaModel(
      id: (json['id_plantilla'] ?? '').toString(),
      nombre: (json['nombre'] ?? '') as String,
      idTipoPrenda: rawTipo is int
          ? rawTipo
          : int.tryParse(rawTipo?.toString() ?? '') ?? 0,
      especificaciones: (json['especificaciones'] ?? '') as String,
      version: rawVersion is int
          ? rawVersion
          : int.tryParse(rawVersion?.toString() ?? '') ?? 1,
      activa: (json['activo'] as bool?) ?? true,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// Solo los campos directos de `plantilla_prenda`. NO incluye id_plantilla
  /// ni created_at (los genera la BD en insert). El campo `version` se
  /// excluye en INSERT (default 1 en BD) y se incluye con el incremento en
  /// UPDATE — eso lo decide el service según la operación.
  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'id_tipo_prenda': idTipoPrenda,
      'especificaciones': especificaciones,
      'activo': activa,
    };
  }

  // ─── HELPERS DE PRESENTACIÓN ──────────────────────────────────────────────

  // DECISIÓN: si el tipo fue eliminado de la BD, mostrar "Tipo no disponible".
  // RAZÓN: evitar crashes y dar visibilidad al usuario.
  // CAMBIAR: si se quiere ocultar plantillas con tipos eliminados, filtrar
  // en plantillaFiltradoProvider.
  String nombreTipoPrenda(List<TipoPrendaModel> catalogo) {
    final tipo = catalogo.firstWhere(
      (t) => t.id == idTipoPrenda,
      orElse: () => const TipoPrendaModel(id: 0, nombre: 'Tipo no disponible', categoria: ''),
    );
    return tipo.nombre;
  }

  /// Versión formateada estilo "vN" para la UI.
  String get versionLabel => 'v$version';
}
