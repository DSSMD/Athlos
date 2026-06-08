// ============================================================================
// lib/domain/models/notificacion_model.dart
// ============================================================================
// Modelo de Notificación in-app.
//
// Mapea 1:1 con la tabla `notificaciones` (Supabase). La conversión
// snake_case ↔ camelCase ocurre en fromJson / toJson — el resto del front
// consume sólo nombres camelCase.
//
// Decisiones de tipo:
//   - id_notificacion: NOT NULL en BD con default gen_random_uuid(); siempre
//     viene poblado al leer → lo expongo como String non-null.
//   - id_usuario, tipo, titulo, mensaje, prioridad: nullable según schema
//     (la BD los permite NULL para tolerar notificaciones de sistema sin
//     usuario destinatario o sin clasificación). En el front respetamos el
//     mismo nullable.
//   - leida: la columna admite NULL con default false. Lo consolidamos a
//     `bool` non-null usando `?? false` para que la UI no tenga que branchear.
//   - fecha_creacion: BD lo deja nullable con default now(); el front lo
//     trata como non-null y cae a DateTime.now() si llegara null (no debería
//     pasar en lecturas reales, pero evitamos el null en la UI).
// ============================================================================

/// Prioridad de una notificación. Espejo del CHECK CONSTRAINT en BD:
/// prioridad IN ('informativa','advertencia','critica').
enum PrioridadNotificacion {
  informativa,
  advertencia,
  critica;

  /// Convierte el string crudo de la BD al enum. Devuelve null si el valor
  /// es null o no matchea — el caller decide cómo tratar el desconocido
  /// (mostrar como informativa, ignorar, etc.).
  static PrioridadNotificacion? fromString(String? raw) {
    if (raw == null) return null;
    switch (raw.toLowerCase()) {
      case 'informativa':
        return PrioridadNotificacion.informativa;
      case 'advertencia':
        return PrioridadNotificacion.advertencia;
      case 'critica':
        return PrioridadNotificacion.critica;
      default:
        return null;
    }
  }

  /// String exacto que espera el CHECK CONSTRAINT en BD. Coincide con
  /// el nombre del enum case (informativa/advertencia/critica).
  String get toDbString => name;
}

class NotificacionModel {
  const NotificacionModel({
    required this.idNotificacion,
    required this.fechaCreacion,
    this.idUsuario,
    this.tipo,
    this.titulo,
    this.mensaje,
    this.leida = false,
    this.prioridad,
  });

  final String idNotificacion;
  final String? idUsuario;
  final String? tipo;
  final String? titulo;
  final String? mensaje;
  final bool leida;
  final DateTime fechaCreacion;
  final PrioridadNotificacion? prioridad;

  // ─── SERIALIZACIÓN ────────────────────────────────────────────────────────

  /// Construye desde una fila de `notificaciones`. Tolerante a nulls
  /// porque varias columnas en BD admiten NULL (ver header).
  factory NotificacionModel.fromJson(Map<String, dynamic> json) {
    return NotificacionModel(
      idNotificacion: (json['id_notificacion'] ?? '').toString(),
      idUsuario: json['id_usuario'] as String?,
      tipo: json['tipo'] as String?,
      titulo: json['titulo'] as String?,
      mensaje: json['mensaje'] as String?,
      leida: (json['leida'] as bool?) ?? false,
      fechaCreacion:
          DateTime.tryParse(json['fecha_creacion']?.toString() ?? '') ??
          DateTime.now(),
      prioridad: PrioridadNotificacion.fromString(json['prioridad'] as String?),
    );
  }

  /// Solo los campos directos. NO incluye id_notificacion (lo genera la BD)
  /// ni fecha_creacion (default now()) — esos los maneja la inserción.
  Map<String, dynamic> toJson() {
    return {
      'id_usuario': idUsuario,
      'tipo': tipo,
      'titulo': titulo,
      'mensaje': mensaje,
      'leida': leida,
      'prioridad': prioridad?.toDbString,
    };
  }

  // ─── COPYWITH ─────────────────────────────────────────────────────────────

  /// Útil para updates optimistas en el provider (ej. marcar leído sin
  /// esperar la respuesta del service).
  NotificacionModel copyWith({
    String? idNotificacion,
    String? idUsuario,
    String? tipo,
    String? titulo,
    String? mensaje,
    bool? leida,
    DateTime? fechaCreacion,
    PrioridadNotificacion? prioridad,
  }) {
    return NotificacionModel(
      idNotificacion: idNotificacion ?? this.idNotificacion,
      idUsuario: idUsuario ?? this.idUsuario,
      tipo: tipo ?? this.tipo,
      titulo: titulo ?? this.titulo,
      mensaje: mensaje ?? this.mensaje,
      leida: leida ?? this.leida,
      fechaCreacion: fechaCreacion ?? this.fechaCreacion,
      prioridad: prioridad ?? this.prioridad,
    );
  }
}
