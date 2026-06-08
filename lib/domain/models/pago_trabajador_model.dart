// lib/domain/models/pago_trabajador_model.dart

/// Representa un pago individual registrado en la tabla [pagos_trabajador].
/// Cada fila es un movimiento de dinero concreto (adelanto o liquidación).
class PagoTrabajadorModel {
  final String idPago;
  final String idTrabajador;
  final String? idAsignacion; // Nullable: puede ser un adelanto sin lote específico
  final double monto;
  final DateTime fechaPago;
  final String tipoPago; // 'Adelanto' | 'Liquidación'
  final String? notas;

  const PagoTrabajadorModel({
    required this.idPago,
    required this.idTrabajador,
    this.idAsignacion,
    required this.monto,
    required this.fechaPago,
    required this.tipoPago,
    this.notas,
  });

  factory PagoTrabajadorModel.fromJson(Map<String, dynamic> json) {
    return PagoTrabajadorModel(
      idPago: json['id_pago']?.toString() ?? '',
      idTrabajador: json['id_trabajador']?.toString() ?? '',
      idAsignacion: json['id_asignacion']?.toString(),
      monto: (json['monto'] as num?)?.toDouble() ?? 0.0,
      fechaPago: json['fecha_pago'] != null
          ? DateTime.parse(json['fecha_pago'].toString())
          : DateTime.now(),
      tipoPago: json['tipo_pago']?.toString() ?? 'Adelanto',
      notas: json['notas']?.toString(),
    );
  }
}

/// Representa una fila de la VIEW [vista_pagos_produccion_por_orden].
/// Agrupa todos los lotes que un trabajador tiene en una orden específica,
/// con los totales pactados, adelantos entregados y saldo pendiente.
class ResumenPagoProduccionModel {
  final String numOrden;
  final String idTrabajador;
  final String trabajadorNombre;
  final String area;
  final int lotesAsignados;
  final double totalPactado;
  final double totalAdelantos;
  final double saldoPendiente;

  /// 'Pendiente' | 'Con Adelantos' | 'Liquidado'
  final String estadoPagoGlobal;

  const ResumenPagoProduccionModel({
    required this.numOrden,
    required this.idTrabajador,
    required this.trabajadorNombre,
    required this.area,
    required this.lotesAsignados,
    required this.totalPactado,
    required this.totalAdelantos,
    required this.saldoPendiente,
    required this.estadoPagoGlobal,
  });

  factory ResumenPagoProduccionModel.fromJson(Map<String, dynamic> json) {
    return ResumenPagoProduccionModel(
      numOrden: json['num_orden']?.toString() ?? '',
      idTrabajador: json['id_trabajador']?.toString() ?? '',
      trabajadorNombre: json['trabajador_nombre']?.toString() ?? 'Sin nombre',
      area: json['area']?.toString() ?? 'Sin área',
      lotesAsignados: (json['lotes_asignados'] as num?)?.toInt() ?? 0,
      totalPactado: (json['total_pactado'] as num?)?.toDouble() ?? 0.0,
      totalAdelantos: (json['total_adelantos'] as num?)?.toDouble() ?? 0.0,
      saldoPendiente: (json['saldo_pendiente'] as num?)?.toDouble() ?? 0.0,
      estadoPagoGlobal: json['estado_pago_global']?.toString() ?? 'Pendiente',
    );
  }
}
