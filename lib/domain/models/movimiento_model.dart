// Tipos de movimiento de inventario.
// TODO Den: ajustar/agregar tipos según necesidades reales del negocio.
enum TipoMovimiento {
  ingreso, // entrada manual (compra, recepción)
  salida, // salida manual (uso en producción manual)
  auto, // descuento automático del sistema (orden de producción)
  ajuste, // corrección manual (inventario físico vs registrado)
}

extension TipoMovimientoLabel on TipoMovimiento {
  String get label {
    switch (this) {
      case TipoMovimiento.ingreso:
        return 'Ingreso';
      case TipoMovimiento.salida:
        return 'Salida';
      case TipoMovimiento.auto:
        return 'Auto';
      case TipoMovimiento.ajuste:
        return 'Ajuste';
    }
  }
}

// Áreas operativas del taller textil.
// TODO Den: confirmar/cambiar áreas reales según organización del taller.
enum AreaMovimiento { sublimado, bordado, corte, general }

extension AreaMovimientoLabel on AreaMovimiento {
  String get label {
    switch (this) {
      case AreaMovimiento.sublimado:
        return 'Sublimado';
      case AreaMovimiento.bordado:
        return 'Bordado';
      case AreaMovimiento.corte:
        return 'Corte';
      case AreaMovimiento.general:
        return 'General';
    }
  }
}

class MovimientoModel {
  const MovimientoModel({
    required this.id,
    required this.idInsumo,
    required this.tipo,
    required this.cantidad,
    required this.motivo,
    required this.fecha,
    required this.usuario,
    required this.area,
    required this.referencia,
    required this.stockAntes,
    required this.stockDespues,
  });

  final String id;
  final String idInsumo;
  final TipoMovimiento tipo;
  final double cantidad;
  final String motivo;
  final DateTime fecha;
  final String usuario;
  final AreaMovimiento area;
  final String referencia;
  final double stockAntes;
  final double stockDespues;

  // =========================================================================
  // AQUÍ ESTÁ LA MAGIA: EL FROM_JSON PARA CONECTAR CON SUPABASE
  // =========================================================================
  factory MovimientoModel.fromJson(Map<String, dynamic> json) {
    // 1. Leemos los datos crudos de la base de datos
    int idEstado = json['id_estado_mov'] as int? ?? 1;
    String motivoCrudo = json['motivo']?.toString() ?? 'Sin motivo';

    // 2. MAGIA: Desciframos el tipo real basado en la etiqueta secreta
    TipoMovimiento tipoBD = (idEstado == 2)
        ? TipoMovimiento.salida
        : TipoMovimiento.ingreso;

    if (motivoCrudo.startsWith('[AUTO]')) {
      tipoBD = TipoMovimiento.auto;
      motivoCrudo = motivoCrudo.replaceFirst(
        '[AUTO] ',
        '',
      ); // Limpiamos el texto
    } else if (motivoCrudo.startsWith('[AJUSTE]')) {
      tipoBD = TipoMovimiento.ajuste;
      motivoCrudo = motivoCrudo.replaceFirst(
        '[AJUSTE] ',
        '',
      ); // Limpiamos el texto
    }

    // 2. Extraer el UUID generado por Supabase para la referencia
    final String idStr = json['id_movimiento']?.toString() ?? '';
    final String refVisual = idStr.length >= 6
        ? 'MOV-${idStr.substring(0, 6).toUpperCase()}'
        : 'MOV-MANUAL';

    return MovimientoModel(
      id: idStr,
      idInsumo: json['id_insumo']?.toString() ?? '',
      tipo: tipoBD,
      // Aseguramos que la cantidad se lea perfecto aunque la BD mande un string decimal
      cantidad: json['cantidad'] != null
          ? double.tryParse(json['cantidad'].toString()) ?? 0.0
          : 0.0,
      motivo: json['motivo']?.toString() ?? 'Sin motivo',
      fecha: json['fecha'] != null
          ? DateTime.parse(json['fecha'])
          : DateTime.now(),
      usuario: 'Sistema',
      area: AreaMovimiento.general,
      referencia: refVisual,
      stockAntes: 0.0,
      stockDespues: 0.0,
    );
  }
}
