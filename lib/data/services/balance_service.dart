// lib/data/services/balance_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/balance_model.dart';

class BalanceService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ─────────────────────────────────────────────────────────────────────────
  // 1. RESUMEN GLOBAL: Ingresos (órdenes) + Egresos (pagos trabajadores)
  //    para el período dado.
  // ─────────────────────────────────────────────────────────────────────────
  Future<ResumenBalanceModel> getResumenBalance({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final hastaEffective = hasta ?? DateTime.now();

    // ── Ingresos: sum de costo_total en órdenes del período ──
    // Usamos dynamic para permitir reasignación entre FilterBuilder y TransformBuilder
    dynamic ordenQuery = _supabase
        .from('orden')
        .select('costo_total, fecha_orden');

    if (desde != null) {
      ordenQuery = ordenQuery.gte('fecha_orden', desde.toIso8601String());
    }
    ordenQuery = ordenQuery.lte('fecha_orden', hastaEffective.toIso8601String());

    final List ordenesRes = await ordenQuery;
    final double ingresos = ordenesRes.fold<double>(
      0.0,
      (sum, row) => sum + ((row['costo_total'] as num?)?.toDouble() ?? 0.0),
    );

    // ── Egresos: sum de monto en pagos_trabajador del período ──
    dynamic pagosQuery = _supabase
        .from('pagos_trabajador')
        .select('monto, fecha_pago');

    if (desde != null) {
      pagosQuery = pagosQuery.gte('fecha_pago', desde.toIso8601String());
    }
    pagosQuery = pagosQuery.lte('fecha_pago', hastaEffective.toIso8601String());

    final List pagosRes = await pagosQuery;
    final double egresos = pagosRes.fold<double>(
      0.0,
      (sum, row) => sum + ((row['monto'] as num?)?.toDouble() ?? 0.0),
    );

    return ResumenBalanceModel(
      ingresosTotales: ingresos,
      egresosTotales: egresos,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 2. TABLA DE ÓRDENES CON SUS COSTOS DE PRODUCCIÓN
  //    Cruza órdenes con los pagos_trabajador agrupados por orden.
  // ─────────────────────────────────────────────────────────────────────────
  Future<List<OrdenBalanceModel>> getOrdenesConBalance({
    DateTime? desde,
    DateTime? hasta,
  }) async {
    final hastaEffective = hasta ?? DateTime.now();

    // Traemos las órdenes del período con datos básicos
    dynamic ordenQuery = _supabase.from('orden').select('''
      num_orden,
      costo_total,
      fecha_orden,
      estado_orden:id_estado ( nombre_estado ),
      estado_pago:id_estado_pago ( nombre_estado ),
      cliente ( nom_cliente, apellido_cliente )
    ''');

    if (desde != null) {
      ordenQuery = ordenQuery.gte('fecha_orden', desde.toIso8601String());
    }
    // .order() cambia el tipo a TransformBuilder, lo manejamos via dynamic
    ordenQuery = ordenQuery
        .lte('fecha_orden', hastaEffective.toIso8601String())
        .order('fecha_orden', ascending: false);

    final List ordenes = await ordenQuery;

    if (ordenes.isEmpty) return [];

    // Traemos todos los pagos_trabajador con su asignacion → lote → num_orden
    final List pagosRes = await _supabase
        .from('pagos_trabajador')
        .select('''
          monto,
          fecha_pago,
          asignaciones_lote (
            lote ( num_orden )
          )
        ''');

    // Agrupamos los egresos por num_orden
    final Map<String, double> egresosPorOrden = {};
    for (final pago in pagosRes) {
      final asig = pago['asignaciones_lote'];
      if (asig == null) continue;
      final lote = asig['lote'];
      if (lote == null) continue;
      final numOrden = lote['num_orden']?.toString() ?? '';
      if (numOrden.isEmpty) continue;

      // Filtro por fecha (solo pagos en el período)
      if (pago['fecha_pago'] != null) {
        final fecha = DateTime.tryParse(pago['fecha_pago'].toString());
        if (fecha != null) {
          if (desde != null && fecha.isBefore(desde)) continue;
          if (fecha.isAfter(hastaEffective)) continue;
        }
      }

      final monto = (pago['monto'] as num?)?.toDouble() ?? 0.0;
      egresosPorOrden[numOrden] = (egresosPorOrden[numOrden] ?? 0.0) + monto;
    }

    // Mapeamos órdenes a OrdenBalanceModel
    return ordenes.map((row) {
      final numOrden = row['num_orden']?.toString() ?? '';
      final cliente = row['cliente'] as Map<String, dynamic>?;
      final nombre = cliente?['nom_cliente'] ?? '';
      final apellido = cliente?['apellido_cliente'] ?? '';
      final eOrden = row['estado_orden'] as Map<String, dynamic>?;
      final ePago = row['estado_pago'] as Map<String, dynamic>?;

      return OrdenBalanceModel(
        numOrden: numOrden,
        clienteNombre: '$nombre $apellido'.trim(),
        fechaOrden: DateTime.tryParse(row['fecha_orden'].toString()) ?? DateTime.now(),
        estadoOrden: eOrden?['nombre_estado']?.toString() ?? 'Desconocido',
        estadoPago: ePago?['nombre_estado']?.toString() ?? 'Pendiente',
        ingresoVenta: (row['costo_total'] as num?)?.toDouble() ?? 0.0,
        costoProduccion: egresosPorOrden[numOrden] ?? 0.0,
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3. SERIES HISTÓRICAS para el gráfico de barras dobles
  //    Devuelve ingresos y egresos agrupados en N períodos del rango.
  // ─────────────────────────────────────────────────────────────────────────
  Future<List<BalanceDataPoint>> getSeriesHistoricas(BalancePeriodo periodo) async {
    final now = DateTime.now();
    final desde = periodo.fechaDesde;

    final List<_Bucket> buckets = _buildBuckets(periodo, now, desde);

    // Traemos órdenes
    dynamic ordenQuery = _supabase
        .from('orden')
        .select('costo_total, fecha_orden');
    if (desde != null) {
      ordenQuery = ordenQuery.gte('fecha_orden', desde.toIso8601String());
    }
    final List ordenesRaw = await ordenQuery;

    // Traemos pagos
    dynamic pagosQuery = _supabase
        .from('pagos_trabajador')
        .select('monto, fecha_pago');
    if (desde != null) {
      pagosQuery = pagosQuery.gte('fecha_pago', desde.toIso8601String());
    }
    final List pagosRaw = await pagosQuery;

    // Asignamos a cada bucket
    for (final o in ordenesRaw) {
      final fecha = DateTime.tryParse(o['fecha_orden'].toString());
      if (fecha == null) continue;
      final monto = (o['costo_total'] as num?)?.toDouble() ?? 0.0;
      for (final b in buckets) {
        if (!fecha.isBefore(b.inicio) && fecha.isBefore(b.fin)) {
          b.ingresos += monto;
          break;
        }
      }
    }

    for (final p in pagosRaw) {
      final fecha = DateTime.tryParse(p['fecha_pago'].toString());
      if (fecha == null) continue;
      final monto = (p['monto'] as num?)?.toDouble() ?? 0.0;
      for (final b in buckets) {
        if (!fecha.isBefore(b.inicio) && fecha.isBefore(b.fin)) {
          b.egresos += monto;
          break;
        }
      }
    }

    return buckets
        .map((b) => BalanceDataPoint(
              label: b.label,
              ingresos: b.ingresos,
              egresos: b.egresos,
            ))
        .toList();
  }

  List<_Bucket> _buildBuckets(BalancePeriodo periodo, DateTime now, DateTime? desde) {
    switch (periodo) {
      case BalancePeriodo.semana:
        return List.generate(7, (i) {
          final d = now.subtract(Duration(days: 6 - i));
          final inicio = DateTime(d.year, d.month, d.day);
          final fin = inicio.add(const Duration(days: 1));
          const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
          return _Bucket(
            inicio: inicio,
            fin: fin,
            label: dias[inicio.weekday - 1],
          );
        });

      case BalancePeriodo.mes:
        return List.generate(4, (i) {
          final inicio = now.subtract(Duration(days: 7 * (3 - i)));
          final fin = inicio.add(const Duration(days: 7));
          return _Bucket(
            inicio: DateTime(inicio.year, inicio.month, inicio.day),
            fin: DateTime(fin.year, fin.month, fin.day),
            label: 'Sem ${i + 1}',
          );
        });

      case BalancePeriodo.trimestre:
        return List.generate(3, (i) {
          final mesIdx = now.month - (2 - i);
          final year = mesIdx <= 0 ? now.year - 1 : now.year;
          final mes = mesIdx <= 0 ? mesIdx + 12 : mesIdx;
          final inicio = DateTime(year, mes, 1);
          final fin = DateTime(year, mes + 1, 1);
          const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
          return _Bucket(
            inicio: inicio,
            fin: fin,
            label: meses[mes - 1],
          );
        });

      case BalancePeriodo.todo:
        return List.generate(6, (i) {
          final mesIdx = now.month - (5 - i);
          final year = mesIdx <= 0 ? now.year - 1 : now.year;
          final mes = mesIdx <= 0 ? mesIdx + 12 : mesIdx;
          final inicio = DateTime(year, mes, 1);
          final fin = DateTime(year, mes + 1, 1);
          const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
          return _Bucket(
            inicio: inicio,
            fin: fin,
            label: meses[mes - 1],
          );
        });
    }
  }
}

/// Punto de datos para el gráfico de barras dobles
class BalanceDataPoint {
  final String label;
  final double ingresos;
  final double egresos;
  double get ganancia => ingresos - egresos;

  const BalanceDataPoint({
    required this.label,
    required this.ingresos,
    required this.egresos,
  });
}

/// Bucket interno para agrupar datos por período
class _Bucket {
  final DateTime inicio;
  final DateTime fin;
  final String label;
  double ingresos;
  double egresos;

  _Bucket({
    required this.inicio,
    required this.fin,
    required this.label,
    this.ingresos = 0.0,
    this.egresos = 0.0,
  });
}
