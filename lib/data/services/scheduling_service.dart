// ============================================================================
// lib/data/services/scheduling_service.dart
// ============================================================================
// Servicio del módulo de Scheduling (Moore-Hodgson).
//
// Responsabilidades:
//   1. Leer órdenes activas de Supabase con sus detalles (tiempos calculados).
//   2. Leer la configuración de capacidad del taller (config_produccion).
//   3. Ejecutar el algoritmo Moore-Hodgson en Dart puro (sin RPC).
//   4. Persistir resultados en scheduling_resultado.
//
// El algoritmo Moore-Hodgson:
//   - Objetivo: minimizar el número de órdenes que se entregan tarde.
//   - Complejidad: O(n log n) — perfectamente manejable en el frontend.
//   - Input: órdenes ordenadas por fecha de entrega (EDD).
//   - Output: conjunto S = órdenes que llegan a tiempo, resto = tarde.
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/scheduling_model.dart';

class SchedulingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ═══════════════════════════════════════════════════════════════════════════
  // 1. OBTENER DATOS DE ÓRDENES PARA SCHEDULING
  // ═══════════════════════════════════════════════════════════════════════════

  /// Obtiene las órdenes activas (Pendiente + En Producción) con sus
  /// detalles de tallas y tiempos de producción por plantilla.
  ///
  /// Calcula p[j] (tiempo de proceso) para cada orden:
  ///   p[j] = Σ por cada detalle:
  ///            Σ por cada talla: cantidad × tiempo_produccion_unitario
  ///   Para conjuntos: se usa el tiempo de cada plantilla componente
  ///   multiplicado por su cantidad_por_conjunto.
  Future<List<OrdenSchedulingInput>> obtenerOrdenesParaScheduling() async {
    try {
      // Estados activos: 1 = Pendiente, 2 = En Producción
      final response = await _supabase
          .from('orden')
          .select('''
            num_orden,
            fecha_orden,
            fecha_entrega,
            prioridad,
            id_estado,
            cliente (nom_cliente, apellido_cliente),
            detalle_orden (
              id_conjunto,
              id_plantilla,
              cantidad_total,
              plantilla_prenda (
                tiempo_produccion_unitario
              ),
              conjunto (
                conjunto_plantilla (
                  cantidad_por_conjunto,
                  plantilla_prenda (
                    tiempo_produccion_unitario
                  )
                )
              ),
              detalle_orden_talla (
                cantidad
              )
            )
          ''')
          .inFilter('id_estado', [1, 2])
          .order('fecha_entrega', ascending: true);

      final ordenes = <OrdenSchedulingInput>[];

      for (final raw in (response as List<dynamic>)) {
        final orden = raw as Map<String, dynamic>;
        final cliente = orden['cliente'] as Map<String, dynamic>? ?? {};
        final detalles = orden['detalle_orden'] as List<dynamic>? ?? [];

        final nombre =
            '${cliente['nom_cliente'] ?? ''} ${cliente['apellido_cliente'] ?? ''}'
                .trim();

        // ── Calcular p[j] ─────────────────────────────────────────────────
        double tiempoProceso = 0.0;

        for (final det in detalles) {
          final detMap = det as Map<String, dynamic>;
          final tallas = detMap['detalle_orden_talla'] as List<dynamic>? ?? [];
          final cantidadTotal = tallas.fold<int>(
            0,
            (sum, t) => sum + ((t as Map)['cantidad'] as num).toInt(),
          );

          if (cantidadTotal == 0) continue;

          final esConjunto = detMap['id_conjunto'] != null;

          if (!esConjunto) {
            // Plantilla directa
            final plantillaData =
                detMap['plantilla_prenda'] as Map<String, dynamic>?;
            final tiempoUnit = double.tryParse(
                  plantillaData?['tiempo_produccion_unitario']?.toString() ??
                      '0',
                ) ??
                0.0;
            tiempoProceso += cantidadTotal * tiempoUnit;
          } else {
            // Conjunto: sumar tiempo de cada plantilla componente
            final conjuntoData =
                detMap['conjunto'] as Map<String, dynamic>? ?? {};
            final cpList =
                conjuntoData['conjunto_plantilla'] as List<dynamic>? ?? [];
            for (final cp in cpList) {
              final cpMap = cp as Map<String, dynamic>;
              final cantCP =
                  (cpMap['cantidad_por_conjunto'] as num?)?.toInt() ?? 1;
              final pData = cpMap['plantilla_prenda'] as Map<String, dynamic>?;
              final tiempoUnit = double.tryParse(
                    pData?['tiempo_produccion_unitario']?.toString() ?? '0',
                  ) ??
                  0.0;
              // horas = cantidadTotal (conjuntos) × cantidadPorConjunto × tiempoUnit
              tiempoProceso += cantidadTotal * cantCP * tiempoUnit;
            }
          }
        }

        ordenes.add(
          OrdenSchedulingInput(
            numOrden: orden['num_orden'] as String,
            clienteNombre: nombre.isEmpty ? 'Cliente N/A' : nombre,
            fechaEntrega: DateTime.parse(orden['fecha_entrega'] as String),
            tiempoProceso: tiempoProceso,
            prioridad:
                (orden['prioridad'] as String?)?.toLowerCase() ?? 'normal',
            fechaOrden: DateTime.parse(orden['fecha_orden'] as String),
          ),
        );
      }

      return ordenes;
    } catch (e) {
      throw Exception('Error al obtener órdenes para scheduling: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 2. OBTENER CAPACIDAD DEL TALLER
  // ═══════════════════════════════════════════════════════════════════════════

  Future<double> obtenerCapacidadHorasDia() async {
    try {
      final response = await _supabase
          .from('config_produccion')
          .select('capacidad_horas_dia')
          .eq('id_config', 1)
          .single();
      return double.tryParse(
            response['capacidad_horas_dia']?.toString() ?? '8',
          ) ??
          8.0;
    } catch (_) {
      return 8.0; // fallback seguro
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 3. ALGORITMO MOORE-HODGSON (Dart puro)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Ejecuta el algoritmo de Moore-Hodgson sobre la lista de órdenes.
  ///
  /// [ordenes]          : lista de órdenes para secuenciar.
  /// [capacidadHorasDia]: horas productivas por día del taller (default 8).
  /// [fechaInicio]      : momento desde el que se calcula (default = ahora).
  ///
  /// Retorna la lista completa de resultados (en-tiempo + tarde), ordenada
  /// por su posición en la secuencia (las tarde van al final con posición 999).
  List<OrdenSchedulingResult> ejecutarMooreHodgson(
    List<OrdenSchedulingInput> ordenes, {
    double capacidadHorasDia = 8.0,
    DateTime? fechaInicio,
  }) {
    if (ordenes.isEmpty) return [];

    final ahora = fechaInicio ?? DateTime.now();

    // ── Paso 1: Ordenar por EDD (fecha entrega ASC), desempate por prioridad
    final sorted = [...ordenes];
    sorted.sort((a, b) {
      final cmpFecha = a.fechaEntrega.compareTo(b.fechaEntrega);
      if (cmpFecha != 0) return cmpFecha;
      return a.pesoPrioridad.compareTo(b.pesoPrioridad);
    });

    // ── Paso 2: Algoritmo Moore-Hodgson
    // S = conjunto de órdenes que entran en el schedule a tiempo.
    // T = tiempo acumulado en horas.
    final List<OrdenSchedulingInput> S = []; // programadas (a tiempo)
    double T = 0.0;

    for (final orden in sorted) {
      S.add(orden);
      T += orden.tiempoProceso;

      // ¿La orden actual llegaría tarde?
      final horasHastaVencimiento = _horasHastaFecha(ahora, orden.fechaEntrega);

      if (T > horasHastaVencimiento) {
        // Buscar la orden en S con MAYOR tiempo de proceso y eliminarla
        OrdenSchedulingInput? maxOrden;
        double maxTiempo = -1;
        for (final o in S) {
          if (o.tiempoProceso > maxTiempo) {
            maxTiempo = o.tiempoProceso;
            maxOrden = o;
          }
        }
        if (maxOrden != null) {
          S.remove(maxOrden);
          T -= maxOrden.tiempoProceso;
        }
      }
    }

    // ── Paso 3: Calcular fechas estimadas para el conjunto S
    // Las órdenes en S se pueden entregar a tiempo; las que no están en S, no.
    final enTiempoIds = S.map((o) => o.numOrden).toSet();

    // Construir mapa: orden → resultado
    final Map<String, OrdenSchedulingResult> resultados = {};

    // Procesar las órdenes EN TIEMPO (en su orden óptimo)
    double acumulado = 0.0;
    int posicion = 1;
    for (final orden in S) {
      final inicio = acumulado;
      final fin = acumulado + orden.tiempoProceso;
      final fechaFin = _sumarHorasHabiles(ahora, fin, capacidadHorasDia);

      resultados[orden.numOrden] = OrdenSchedulingResult(
        input: orden,
        posicionSecuencia: posicion++,
        tiempoInicioEstimado: inicio,
        tiempoFinEstimado: fin,
        fechaFinEstimada: fechaFin,
        enTiempo: true,
      );
      acumulado = fin;
    }

    // Procesar las órdenes CON RETRASO (van al final en orden EDD)
    final conRetraso = sorted
        .where((o) => !enTiempoIds.contains(o.numOrden))
        .toList();
    for (final orden in conRetraso) {
      final inicio = acumulado;
      final fin = acumulado + orden.tiempoProceso;
      final fechaFin = _sumarHorasHabiles(ahora, fin, capacidadHorasDia);

      resultados[orden.numOrden] = OrdenSchedulingResult(
        input: orden,
        posicionSecuencia: posicion++,
        tiempoInicioEstimado: inicio,
        tiempoFinEstimado: fin,
        fechaFinEstimada: fechaFin,
        enTiempo: false,
      );
      acumulado = fin;
    }

    // Devolver en orden de posición
    final lista = resultados.values.toList()
      ..sort((a, b) => a.posicionSecuencia.compareTo(b.posicionSecuencia));
    return lista;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 4. PERSISTIR RESULTADOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Borra los resultados anteriores e inserta los nuevos.
  Future<void> guardarResultados(
    List<OrdenSchedulingResult> resultados,
  ) async {
    try {
      // Borrar resultados anteriores
      await _supabase.from('scheduling_resultado').delete().neq(
            'id_resultado',
            '00000000-0000-0000-0000-000000000000',
          );

      if (resultados.isEmpty) return;

      // Insertar nuevos resultados
      final filas = resultados
          .map(
            (r) => {
              'num_orden': r.numOrden,
              'posicion_secuencia': r.posicionSecuencia,
              'tiempo_inicio_estimado': r.tiempoInicioEstimado,
              'tiempo_fin_estimado': r.tiempoFinEstimado,
              'fecha_fin_estimada': r.fechaFinEstimada.toIso8601String().split('T')[0],
              'en_tiempo': r.enTiempo,
              'tiempo_proceso_calculado': r.tiempoProceso,
            },
          )
          .toList();

      await _supabase.from('scheduling_resultado').insert(filas);
    } catch (e) {
      throw Exception('Error al guardar resultados de scheduling: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS PRIVADOS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calcula las horas disponibles desde [desde] hasta [hasta],
  /// asumiendo días completos de 24 horas calendario
  /// (el ajuste a horas hábiles lo hace _sumarHorasHabiles).
  double _horasHastaFecha(DateTime desde, DateTime hasta) {
    final diff = hasta.difference(desde);
    return diff.inMinutes / 60.0;
  }

  /// Dado un número de [horasHabiles], calcula la fecha calendario
  /// en la que se terminan, asumiendo [horasPorDia] horas hábiles/día.
  DateTime _sumarHorasHabiles(
    DateTime desde,
    double horasHabiles,
    double horasPorDia,
  ) {
    if (horasHabiles <= 0 || horasPorDia <= 0) return desde;
    final diasCompletos = (horasHabiles / horasPorDia).floor();
    final horasResto = horasHabiles % horasPorDia;
    return desde
        .add(Duration(days: diasCompletos))
        .add(Duration(minutes: (horasResto * 60).round()));
  }
}
