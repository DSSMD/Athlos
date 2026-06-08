// lib/data/services/pago_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/pago_trabajador_model.dart';

class PagoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ──────────────────────────────────────────────────────────────────────────
  // 1. RESUMEN POR ORDEN (usa la VIEW vista_pagos_produccion_por_orden)
  //    Devuelve un fila por cada trabajador que tocó la orden, con sus totales.
  // ──────────────────────────────────────────────────────────────────────────
  Future<List<ResumenPagoProduccionModel>> getResumenPagosPorOrden(
    String numOrden,
  ) async {
    try {
      final response = await _supabase
          .from('vista_pagos_produccion_por_orden')
          .select()
          .eq('num_orden', numOrden)
          .order('trabajador_nombre', ascending: true);

      return (response as List)
          .map((json) => ResumenPagoProduccionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener resumen de pagos de producción: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 2. HISTORIAL DE PAGOS DE UN TRABAJADOR EN UNA ORDEN
  //    Para el drawer de detalle al tocar una fila del resumen.
  // ──────────────────────────────────────────────────────────────────────────
  Future<List<PagoTrabajadorModel>> getPagosPorTrabajadorEnOrden(
    String idTrabajador,
    String numOrden,
  ) async {
    try {
      // Unimos pagos_trabajador → asignaciones_lote → lote para filtrar por orden
      final response = await _supabase
          .from('pagos_trabajador')
          .select('''
            id_pago,
            id_trabajador,
            id_asignacion,
            monto,
            fecha_pago,
            tipo_pago,
            notas,
            asignaciones_lote (
              lote ( num_orden )
            )
          ''')
          .eq('id_trabajador', idTrabajador)
          .order('fecha_pago', ascending: false);

      // Filtramos en memoria por num_orden (el JOIN anidado no permite
      // filtrar directamente por columna de relación en PostgREST fácilmente)
      final filtrados = (response as List).where((item) {
        final asignacion = item['asignaciones_lote'];
        if (asignacion == null) return false;
        final lote = asignacion['lote'];
        if (lote == null) return false;
        return lote['num_orden']?.toString() == numOrden;
      }).toList();

      return filtrados
          .map((json) => PagoTrabajadorModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener historial de pagos del trabajador: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 3. TODOS LOS PAGOS DE UN TRABAJADOR (para la sección de Usuarios/Trabajadores)
  // ──────────────────────────────────────────────────────────────────────────
  Future<List<PagoTrabajadorModel>> getTodosPagosPorTrabajador(
    String idTrabajador,
  ) async {
    try {
      final response = await _supabase
          .from('pagos_trabajador')
          .select()
          .eq('id_trabajador', idTrabajador)
          .order('fecha_pago', ascending: false);

      return (response as List)
          .map((json) => PagoTrabajadorModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener pagos del trabajador: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 4. SALDOS GLOBALES DE TODOS LOS TRABAJADORES
  //    Para la pestaña "Trabajadores" en UsuariosPage.
  //    Usa la vista agrupando por trabajador (sin filtro de orden).
  // ──────────────────────────────────────────────────────────────────────────
  Future<List<ResumenPagoProduccionModel>> getSaldosGlobalesTrabajadores() async {
    try {
      // La VIEW incluye num_orden, pero podemos agrupar en Dart sumando
      // los totales de cada trabajador sin importar la orden.
      // Traemos todos los registros y agrupamos en memoria.
      final response = await _supabase
          .from('vista_pagos_produccion_por_orden')
          .select()
          .order('trabajador_nombre', ascending: true);

      final List<dynamic> rows = response as List;

      // Agrupamos por trabajador acumulando sus totales de todas las órdenes
      final Map<String, ResumenPagoProduccionModel> agrupado = {};
      for (final row in rows) {
        final id = row['id_trabajador']?.toString() ?? '';
        if (agrupado.containsKey(id)) {
          final prev = agrupado[id]!;
          final extra = ResumenPagoProduccionModel.fromJson(row);
          agrupado[id] = ResumenPagoProduccionModel(
            numOrden: 'global',
            idTrabajador: prev.idTrabajador,
            trabajadorNombre: prev.trabajadorNombre,
            area: prev.area,
            lotesAsignados: prev.lotesAsignados + extra.lotesAsignados,
            totalPactado: prev.totalPactado + extra.totalPactado,
            totalAdelantos: prev.totalAdelantos + extra.totalAdelantos,
            saldoPendiente: prev.saldoPendiente + extra.saldoPendiente,
            estadoPagoGlobal: _calcularEstadoGlobal(
              prev.totalPactado + extra.totalPactado,
              prev.totalAdelantos + extra.totalAdelantos,
            ),
          );
        } else {
          agrupado[id] = ResumenPagoProduccionModel.fromJson(row);
        }
      }

      return agrupado.values.toList();
    } catch (e) {
      throw Exception('Error al obtener saldos globales de trabajadores: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 5. REGISTRAR UN PAGO (adelanto o liquidación)
  // ──────────────────────────────────────────────────────────────────────────
  Future<void> registrarPago({
    required String idTrabajador,
    required double monto,
    required String tipoPago, // 'Adelanto' | 'Liquidación'
    String? idAsignacion,
    String? notas,
  }) async {
    try {
      await _supabase.from('pagos_trabajador').insert({
        'id_trabajador': idTrabajador,
        'monto': monto,
        'tipo_pago': tipoPago,
        'id_asignacion': ?idAsignacion,
        if (notas != null && notas.isNotEmpty) 'notas': notas,
        // fecha_pago se genera automáticamente con DEFAULT now()
      });

      // Si es una Liquidación, actualizamos el estado_pago de la asignación
      if (tipoPago == 'Liquidación' && idAsignacion != null) {
        await _supabase
            .from('asignaciones_lote')
            .update({'estado_pago': 'Pagado'})
            .eq('id_asignacion', idAsignacion);
      } else if (tipoPago == 'Adelanto' && idAsignacion != null) {
        // Si es adelanto vinculado a una asignación, marcamos como Parcial
        // solo si no está ya Pagado
        await _supabase
            .from('asignaciones_lote')
            .update({'estado_pago': 'Parcial'})
            .eq('id_asignacion', idAsignacion)
            .neq('estado_pago', 'Pagado'); // No sobreescribir si ya está Pagado
      }
    } catch (e) {
      throw Exception('Error al registrar el pago: $e');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  String _calcularEstadoGlobal(double pactado, double adelantos) {
    if (pactado <= 0) return 'Pendiente';
    if (adelantos >= pactado) return 'Liquidado';
    if (adelantos > 0) return 'Con Adelantos';
    return 'Pendiente';
  }
}
