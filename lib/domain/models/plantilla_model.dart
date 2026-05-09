// ============================================================================
// lib/domain/models/plantilla_model.dart
// ============================================================================
// Modelo inmutable para una Plantilla de prenda (módulo Diseño de Prendas).
// Esta es una vista DEMO — el modelo está pensado para ser drop-in cuando
// exista la tabla `plantilla_prenda` en Supabase.
// - PlantillaModel: campos finales + const constructor
// - TipoPrenda: enum con label en español + parser tolerante (cae a `otros`)
// - fromJson / toJson con keys snake_case (alineado con InventarioItemModel
//   y ClienteModel del proyecto)
// ============================================================================

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

// ─── MODELO ─────────────────────────────────────────────────────────────────

class PlantillaModel {
  const PlantillaModel({
    required this.id,
    required this.nombre,
    required this.tipoPrenda,
    required this.version,
    required this.createdAt,
    this.activa = true,
  });

  final String id;
  final String nombre;
  final TipoPrenda tipoPrenda;
  final String version; // ej: "v1.0", "v2.1" — el backend define el formato
  final bool activa;
  final DateTime createdAt;

  // ─── COPYWITH ─────────────────────────────────────────────────────────────

  PlantillaModel copyWith({
    String? id,
    String? nombre,
    TipoPrenda? tipoPrenda,
    String? version,
    bool? activa,
    DateTime? createdAt,
  }) {
    return PlantillaModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      tipoPrenda: tipoPrenda ?? this.tipoPrenda,
      version: version ?? this.version,
      activa: activa ?? this.activa,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // ─── SERIALIZACIÓN ────────────────────────────────────────────────────────

  factory PlantillaModel.fromJson(Map<String, dynamic> json) {
    return PlantillaModel(
      id: json['id'].toString(),
      nombre: (json['nombre'] ?? '') as String,
      tipoPrenda: TipoPrenda.fromString(json['tipo_prenda'] as String?),
      version: (json['version'] ?? '') as String,
      activa: (json['activa'] as bool?) ?? true,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
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
    };
  }
}
