// ============================================================================
// lib/domain/models/plantilla_model.dart
// ============================================================================
// Modelo inmutable para una Plantilla de prenda (módulo Diseño de Prendas).
// Esta es una vista del modelo está pensado para ser drop-in cuando
// exista la tabla `plantilla_prenda` en Supabase.
// - PlantillaModel: campos finales + const constructor
// - TipoPrenda: enum con label en español + parser tolerante (cae a `otros`)
// - fromJson / toJson con keys snake_case (alineado con InventarioItemModel
//   y ClienteModel del proyecto)
// ============================================================================

import 'material_plantilla_model.dart';
import 'medida_punto_model.dart';

// ─── ENUM TIPO DE PRENDA ────────────────────────────────────────────────────

enum TipoPrenda {
  camisas,
  pantalones,
  polleras,
  vestidos,
  chombas,
  otros;

  String get label {
    switch (this) {
      case TipoPrenda.camisas:
        return 'Camisas';
      case TipoPrenda.pantalones:
        return 'Pantalones';
      case TipoPrenda.polleras:
        return 'Polleras';
      case TipoPrenda.vestidos:
        return 'Vestidos';
      case TipoPrenda.chombas:
        return 'Chombas';
      case TipoPrenda.otros:
        return 'Otros';
    }
  }

  /// Parsea un valor crudo de DB a TipoPrenda. Cualquier valor desconocido
  /// (incluido null) cae a `otros` para evitar crashes en runtime.
  static TipoPrenda fromString(String? raw) {
    switch (raw) {
      case 'camisas':
        return TipoPrenda.camisas;
      case 'pantalones':
        return TipoPrenda.pantalones;
      case 'polleras':
        return TipoPrenda.polleras;
      case 'vestidos':
        return TipoPrenda.vestidos;
      case 'chombas':
        return TipoPrenda.chombas;
      default:
        return TipoPrenda.otros;
    }
  }
}

// ─── ENUM TALLA PRENDA ──────────────────────────────────────────────────────

// DECISIÓN: 8 tallas hardcodeadas en el enum (S, M, L, XL, XXL, 2, 4, 6).
// RAZÓN: cubren los rangos típicos textil (adulto + escolar) según el PDF
// de Den (Vista 2 Paso 2). Suficientes para el demo y producción inicial.
// CAMBIAR: si necesitan más tallas (XS, XXXL, talles numéricos extendidos
// 8/10/12), agregar values al enum y actualizar el helper fromString.
//
// Nota: t2/t4/t6 con prefijo "t" porque Dart no permite enum values empezando
// con número. El label muestra "2", "4", "6" (sin la t).
enum TallaPrenda {
  s,
  m,
  l,
  xl,
  xxl,
  t2,
  t4,
  t6;

  String get label {
    switch (this) {
      case TallaPrenda.s:
        return 'S';
      case TallaPrenda.m:
        return 'M';
      case TallaPrenda.l:
        return 'L';
      case TallaPrenda.xl:
        return 'XL';
      case TallaPrenda.xxl:
        return 'XXL';
      case TallaPrenda.t2:
        return '2';
      case TallaPrenda.t4:
        return '4';
      case TallaPrenda.t6:
        return '6';
    }
  }

  /// Parsea la representación serializada al enum. Tolera valores
  /// desconocidos retornando null para que el caller decida (puede
  /// descartar la talla o caer a un default).
  static TallaPrenda? fromString(String? raw) {
    switch (raw) {
      case 's':
        return TallaPrenda.s;
      case 'm':
        return TallaPrenda.m;
      case 'l':
        return TallaPrenda.l;
      case 'xl':
        return TallaPrenda.xl;
      case 'xxl':
        return TallaPrenda.xxl;
      case 't2':
        return TallaPrenda.t2;
      case 't4':
        return TallaPrenda.t4;
      case 't6':
        return TallaPrenda.t6;
      default:
        return null;
    }
  }
}

// ─── MODELO ─────────────────────────────────────────────────────────────────

// DECISIÓN: medidas, materiales y tallasSeleccionadas son listas, no Maps.
// RAZÓN: el orden importa para la UI (orden en que el usuario las agregó).
// CAMBIAR: si se necesita acceso por id, usar helpers `firstWhere` en runtime.
class PlantillaModel {
  const PlantillaModel({
    required this.id,
    required this.nombre,
    required this.tipoPrenda,
    required this.version,
    required this.createdAt,
    this.activa = true,
    this.especificaciones = '',
    this.tallasSeleccionadas = const [],
    this.medidas = const [],
    this.materiales = const [],
  });

  final String id;
  final String nombre;
  final TipoPrenda tipoPrenda;
  final String version; // ej: "v1.0", "v2.1" — el backend define el formato
  final bool activa;
  final DateTime createdAt;

  // Datos del form multi-paso
  final String especificaciones; // texto multilínea (Paso 1)
  final List<TallaPrenda> tallasSeleccionadas; // Paso 2
  final List<MedidaPunto> medidas; // Paso 2
  final List<MaterialPlantilla> materiales; // Paso 3

  // ─── COPYWITH ─────────────────────────────────────────────────────────────

  PlantillaModel copyWith({
    String? id,
    String? nombre,
    TipoPrenda? tipoPrenda,
    String? version,
    bool? activa,
    DateTime? createdAt,
    String? especificaciones,
    List<TallaPrenda>? tallasSeleccionadas,
    List<MedidaPunto>? medidas,
    List<MaterialPlantilla>? materiales,
  }) {
    return PlantillaModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipoPrenda: tipoPrenda ?? this.tipoPrenda,
      version: version ?? this.version,
      activa: activa ?? this.activa,
      createdAt: createdAt ?? this.createdAt,
      especificaciones: especificaciones ?? this.especificaciones,
      tallasSeleccionadas: tallasSeleccionadas ?? this.tallasSeleccionadas,
      medidas: medidas ?? this.medidas,
      materiales: materiales ?? this.materiales,
    );
  }

  // ─── SERIALIZACIÓN ────────────────────────────────────────────────────────

  factory PlantillaModel.fromJson(Map<String, dynamic> json) {
    final rawTallas = (json['tallas_seleccionadas'] as List?) ?? const [];
    final tallas = <TallaPrenda>[];
    for (final t in rawTallas) {
      final parsed = TallaPrenda.fromString(t?.toString());
      if (parsed != null) tallas.add(parsed);
    }

    final rawMedidas = (json['medidas'] as List?) ?? const [];
    final medidas = rawMedidas
        .whereType<Map<String, dynamic>>()
        .map(MedidaPunto.fromJson)
        .toList();

    final rawMateriales = (json['materiales'] as List?) ?? const [];
    final materiales = rawMateriales
        .whereType<Map<String, dynamic>>()
        .map(MaterialPlantilla.fromJson)
        .toList();

    return PlantillaModel(
      id: json['id'].toString(),
      nombre: (json['nombre'] ?? '') as String,
      tipoPrenda: TipoPrenda.fromString(json['tipo_prenda'] as String?),
      version: (json['version'] ?? '') as String,
      activa: (json['activa'] as bool?) ?? true,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      especificaciones: (json['especificaciones'] ?? '') as String,
      tallasSeleccionadas: tallas,
      medidas: medidas,
      materiales: materiales,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'tipo_prenda': tipoPrenda.name,
      'version': version,
      'activa': activa,
      'created_at': createdAt.toIso8601String(),
      'especificaciones': especificaciones,
      'tallas_seleccionadas': tallasSeleccionadas.map((t) => t.name).toList(),
      'medidas': medidas.map((m) => m.toJson()).toList(),
      'materiales': materiales.map((m) => m.toJson()).toList(),
    };
  }
}
