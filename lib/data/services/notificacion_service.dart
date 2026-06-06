// ============================================================================
// lib/data/services/notificacion_service.dart
// ============================================================================
// Servicio del módulo Notificaciones — integración con Supabase.
//
// Tablas que toca:
//   - notificaciones (tabla principal; el trigger BD-side dispara la Edge
//     Function de push fuera del alcance de este service)
//
// Estrategia mock-first:
//   - `useMockData = true` mientras el resto del front se cablea (UI,
//     provider, badge, lista). El service expone la misma firma pública en
//     mock y en real, así que apagar el flag activa todo sin tocar UI ni
//     provider.
//   - Cuando Bloque 4 cablee Supabase Realtime para sincronización en vivo,
//     se agrega `escucharStream(userId)` acá mismo (channel + postgres_changes).
//     No es parte del Bloque 1.
//
// Filtro: SIEMPRE por id_usuario del usuario actual. No hay broadcast por rol
// a nivel BD — si en el futuro se necesita, se hace con una tabla de pivote.
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/notificacion_model.dart';

class NotificacionService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Toggle global mock ↔ real. Cuando se apaga, todas las firmas públicas
  /// siguen funcionando contra la tabla `notificaciones` sin que UI ni
  /// provider necesiten cambios.
  static const bool useMockData = false;

  /// Cap defensivo en lecturas: la lista del bell muestra a lo sumo ~20-30
  /// items. Si más adelante se agrega una pantalla full-history, se levanta
  /// esta restricción ahí, no acá.
  static const int _limit = 30;

  // ─── LECTURA ──────────────────────────────────────────────────────────────

  /// Lista de notificaciones del usuario, ordenadas por fecha desc.
  /// En modo mock devuelve un set fijo (ver `_mockNotificaciones`).
  // Búscalo en tu método obtenerNotificaciones:
  Future<List<NotificacionModel>> obtenerNotificaciones(String userId) async {
    if (useMockData) return _mockNotificaciones(userId);

    try {
      final response = await _client
          .from('notificaciones')
          .select()
          // 🔥 AQUÍ ESTÁ EL CAMBIO: Filtramos por tu ID O porque es nulo (global)
          .or('id_usuario.eq.$userId,id_usuario.is.null')
          .order('fecha_creacion', ascending: false)
          .limit(_limit);

      return (response as List)
          .map((j) => NotificacionModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar notificaciones: $e');
    }
  }

  // ─── ESCRITURA ────────────────────────────────────────────────────────────

  /// Marca una notificación como leída. No-op en modo mock — el provider
  /// hace update optimista local y eso es suficiente para validar UI.
  Future<void> marcarLeida(String idNotificacion) async {
    if (useMockData) return;

    try {
      await _client
          .from('notificaciones')
          .update({'leida': true})
          .eq('id_notificacion', idNotificacion);
    } catch (e) {
      throw Exception('Error al marcar notificación como leída: $e');
    }
  }

  /// Marca todas las no-leídas del usuario en una sola query. Útil para el
  /// botón "marcar todas como leídas" del dropdown.
  Future<void> marcarTodasLeidas(String userId) async {
    if (useMockData) return;

    try {
      await _client
          .from('notificaciones')
          .update({'leida': true})
          .eq('id_usuario', userId)
          .eq('leida', false);
    } catch (e) {
      throw Exception('Error al marcar todas como leídas: $e');
    }
  }

  // ─── HELPERS PRIVADOS ─────────────────────────────────────────────────────

  /// Notificaciones mockeadas que se devuelven mientras `useMockData = true`.
  /// Los ids son determinísticos (NTF-MOCK-NN) para que updates optimistas
  /// en el provider tengan a qué pegarle. Los timestamps son relativos a
  /// DateTime.now() para que el "hace X tiempo" siempre tenga sentido.
  ///
  /// Mix: 4 críticas + 5 advertencias + 5 informativas = 14. 5 leídas / 9 no
  /// leídas, suficiente para que el badge muestre conteo distinto a cero y
  /// para que el botón "marcar todas como leídas" tenga efecto visible.
  List<NotificacionModel> _mockNotificaciones(String userId) {
    final ahora = DateTime.now();
    DateTime hace(Duration d) => ahora.subtract(d);

    final raw = <Map<String, Object?>>[
      // ─── CRÍTICAS ──────────────────────────────────────────────────────
      {
        'id': 'NTF-MOCK-01',
        'tipo': 'orden_retraso',
        'titulo': 'Retraso crítico en ORD-2847',
        'mensaje':
            'La orden de María López tiene 3 días de retraso. El cliente preguntó por el estado.',
        'leida': false,
        'fecha': hace(const Duration(minutes: 2)),
        'prioridad': PrioridadNotificacion.critica,
      },
      {
        'id': 'NTF-MOCK-02',
        'tipo': 'stock_critico',
        'titulo': 'Stock crítico: hilo negro #120',
        'mensaje':
            'Quedan 12 unidades, mínimo recomendado 50. Bloquea producción de poleras.',
        'leida': false,
        'fecha': hace(const Duration(minutes: 18)),
        'prioridad': PrioridadNotificacion.critica,
      },
      {
        'id': 'NTF-MOCK-03',
        'tipo': 'pago_pendiente',
        'titulo': 'Pago pendiente de Tyrone Hernández',
        'mensaje':
            'Anticipo no registrado, la orden ORD-2844 entra en producción mañana.',
        'leida': false,
        'fecha': hace(const Duration(hours: 1, minutes: 12)),
        'prioridad': PrioridadNotificacion.critica,
      },
      {
        'id': 'NTF-MOCK-04',
        'tipo': 'orden_retraso',
        'titulo': 'Retraso en ORD-2812',
        'mensaje':
            'Lote de chalecos para Pedro Sánchez se retrasó 1 día por falta de elástico.',
        'leida': true,
        'fecha': hace(const Duration(hours: 6)),
        'prioridad': PrioridadNotificacion.critica,
      },

      // ─── ADVERTENCIAS ──────────────────────────────────────────────────
      {
        'id': 'NTF-MOCK-05',
        'tipo': 'stock_bajo',
        'titulo': 'Stock bajo: tela poliéster azul',
        'mensaje':
            'Quedan 45 metros, mínimo 100. Reponer antes del cierre semanal.',
        'leida': false,
        'fecha': hace(const Duration(minutes: 35)),
        'prioridad': PrioridadNotificacion.advertencia,
      },
      {
        'id': 'NTF-MOCK-06',
        'tipo': 'stock_bajo',
        'titulo': 'Stock bajo: elástico 3 cm',
        'mensaje': 'Quedan 25 m, mínimo 50 m. Compra sugerida: 100 m.',
        'leida': false,
        'fecha': hace(const Duration(hours: 3)),
        'prioridad': PrioridadNotificacion.advertencia,
      },
      {
        'id': 'NTF-MOCK-07',
        'tipo': 'orden_nueva',
        'titulo': 'Nuevo pedido de Diego Vargas',
        'mensaje':
            'Orden ORD-2851: 20 uniformes escolares, entrega en 10 días.',
        'leida': false,
        'fecha': hace(const Duration(hours: 5)),
        'prioridad': PrioridadNotificacion.advertencia,
      },
      {
        'id': 'NTF-MOCK-08',
        'tipo': 'orden_nueva',
        'titulo': 'Nuevo pedido de Lucía Pérez',
        'mensaje':
            'Orden ORD-2850: 15 camisas polo, taller debe confirmar capacidad.',
        'leida': true,
        'fecha': hace(const Duration(hours: 8)),
        'prioridad': PrioridadNotificacion.advertencia,
      },
      {
        'id': 'NTF-MOCK-09',
        'tipo': 'pago_pendiente',
        'titulo': 'Pago parcial recibido ORD-2839',
        'mensaje': 'Ana Torres pagó solo el 30 % del anticipo acordado.',
        'leida': true,
        'fecha': hace(const Duration(days: 1)),
        'prioridad': PrioridadNotificacion.advertencia,
      },

      // ─── INFORMATIVAS ──────────────────────────────────────────────────
      {
        'id': 'NTF-MOCK-10',
        'tipo': 'orden_finalizada',
        'titulo': 'Orden ORD-2832 finalizada',
        'mensaje': 'Pantalones cargo de Carlos Ruiz listos para entrega.',
        'leida': false,
        'fecha': hace(const Duration(hours: 2)),
        'prioridad': PrioridadNotificacion.informativa,
      },
      {
        'id': 'NTF-MOCK-11',
        'tipo': 'pago_recibido',
        'titulo': 'Pago recibido ORD-2828',
        'mensaje': 'María López pagó Bs. 1,250 — orden cerrada.',
        'leida': false,
        'fecha': hace(const Duration(hours: 9)),
        'prioridad': PrioridadNotificacion.informativa,
      },
      {
        'id': 'NTF-MOCK-12',
        'tipo': 'orden_finalizada',
        'titulo': 'Orden ORD-2825 finalizada',
        'mensaje': 'Chalecos industriales listos para retiro en tienda.',
        'leida': true,
        'fecha': hace(const Duration(days: 1, hours: 4)),
        'prioridad': PrioridadNotificacion.informativa,
      },
      {
        'id': 'NTF-MOCK-13',
        'tipo': 'sistema',
        'titulo': 'Respaldo automático completado',
        'mensaje':
            'Base de datos respaldada con éxito a las 03:00. Sin errores.',
        'leida': true,
        'fecha': hace(const Duration(days: 2)),
        'prioridad': PrioridadNotificacion.informativa,
      },
      {
        'id': 'NTF-MOCK-14',
        'tipo': 'sistema',
        'titulo': 'Actualización del catálogo de tallas',
        'mensaje': 'Se agregaron tallas XXL y XXXL al catálogo de polera v2.',
        'leida': false,
        'fecha': hace(const Duration(days: 3)),
        'prioridad': PrioridadNotificacion.informativa,
      },
    ];

    return raw
        .map(
          (e) => NotificacionModel(
            idNotificacion: e['id'] as String,
            idUsuario: userId,
            tipo: e['tipo'] as String?,
            titulo: e['titulo'] as String?,
            mensaje: e['mensaje'] as String?,
            leida: e['leida'] as bool,
            fechaCreacion: e['fecha'] as DateTime,
            prioridad: e['prioridad'] as PrioridadNotificacion?,
          ),
        )
        .toList();
  }
}
