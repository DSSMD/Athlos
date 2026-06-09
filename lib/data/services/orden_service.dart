import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
//import 'package:workspace/domain/models/detalle_orden_model.dart';
import 'package:workspace/domain/models/orden_model.dart';
import 'package:workspace/domain/models/auditoria_orden_model.dart';
import 'package:workspace/presentation/components/ordenes/orden_draft.dart';

class OrdenService {
  final SupabaseClient _supabase;

  OrdenService(this._supabase);

  // =================================================================
  // LECTURA: LISTA DE ÓRDENES (esquema nuevo)
  // =================================================================
  /// Devuelve la lista de órdenes con sus detalles desplegados.
  /// NO incluye composicion_interna de los conjuntos (es caro y solo se
  /// necesita en el detalle); para la vista de detalle individual, usar
  /// obtenerDetalleOrden(numOrden).
  Future<List<OrdenModel>> obtenerOrdenes() async {
    try {
      final response = await _supabase
          .from('orden')
          .select('''
            num_orden, id_cliente, id_estado, id_estado_pago,
            fecha_orden, fecha_entrega, costo_total, notas_adicionales,
            tiempo_procesamiento_estimado, imagen_modelo, prioridad,
            cliente (nom_cliente, apellido_cliente, num_telefono, ci_cliente, email, direccion),
            estado_orden (nombre_estado),
            estado_pago (nombre_estado),
            detalle_orden (
              id_detalle, id_conjunto, id_plantilla,
              cantidad_total, precio_unitario, subtotal,
              conjunto (nombre),
              plantilla_prenda (nombre, tipo_prenda (nombre_prenda)),
              detalle_orden_talla (id_desglose, id_talla, cantidad, tallas (nombre_talla))
            )
          ''')
          .order('fecha_orden', ascending: false);

      return (response as List<dynamic>)
          .map((json) => OrdenModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener las órdenes: $e');
    }
  }

  // =================================================================
  // LECTURA: DETALLE DE UNA ORDEN (esquema nuevo)
  // =================================================================
  /// Devuelve una orden específica con detalles desplegados INCLUYENDO
  /// composicion_interna para los conjuntos (qué plantillas componen cada
  /// conjunto, desde la tabla conjunto_plantilla).
  Future<OrdenModel> obtenerDetalleOrden(String numOrden) async {
    try {
      final response = await _supabase
          .from('orden')
          .select('''
            num_orden, id_cliente, id_estado, id_estado_pago,
            fecha_orden, fecha_entrega, costo_total, notas_adicionales,
            tiempo_procesamiento_estimado, imagen_modelo, prioridad,
            cliente (nom_cliente, apellido_cliente, num_telefono, ci_cliente, email, direccion),
            estado_orden (nombre_estado),
            estado_pago (nombre_estado),
            detalle_orden (
              id_detalle, id_conjunto, id_plantilla,
              cantidad_total, precio_unitario, subtotal,
              conjunto (
                nombre,
                conjunto_plantilla (cantidad_por_conjunto, plantilla_prenda (nombre))
              ),
              plantilla_prenda (nombre, tipo_prenda (nombre_prenda)),
              detalle_orden_talla (id_desglose, id_talla, cantidad, tallas (nombre_talla))
            )
          ''')
          .eq('num_orden', numOrden)
          .single();

      return OrdenModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al obtener el detalle de la orden: $e');
    }
  }

  // =================================================================
  // ACTUALIZACIÓN DE ESTADO DE ORDEN CON AUDITORÍA
  // =================================================================
  Future<void> actualizarEstadoOrden(
    String numOrden,
    int nuevoIdEstado, {
    String? descripcion,
  }) async {
    try {
      // 1. Obtener el estado actual (anterior) de la orden
      final currentOrder = await _supabase
          .from('orden')
          .select('id_estado')
          .eq('num_orden', numOrden)
          .single();

      final int? estadoAnterior = currentOrder['id_estado'] as int?;

      // 2. Si el estado ya es el mismo, no hacemos nada
      if (estadoAnterior == nuevoIdEstado) return;

      // 3. Actualizar el estado de la orden en la BD
      await _supabase
          .from('orden')
          .update({'id_estado': nuevoIdEstado})
          .eq('num_orden', numOrden);

      // 4. Registrar en la tabla de auditoría (envuelto para que no rompa si falla la FK o RLS)
      try {
        final String? idUsuario = _supabase.auth.currentUser?.id;

        // Validar si el idUsuario existe en la tabla profiles para evitar violación de FK
        bool usuarioExiste = false;
        if (idUsuario != null) {
          final userCheck = await _supabase
              .from('profiles')
              .select('id')
              .eq('id', idUsuario)
              .maybeSingle();
          usuarioExiste = userCheck != null;
        }

        final String desc =
            descripcion ??
            (nuevoIdEstado == 4
                ? 'Pedido entregado al cliente'
                : nuevoIdEstado == 3
                ? 'Producción finalizada de todos los lotes'
                : 'Avance de estado de orden');

        await _supabase.from('auditoria_ordenes').insert({
          'num_orden': numOrden,
          'id_usuario': usuarioExiste ? idUsuario : null,
          'estado_anterior_id': estadoAnterior,
          'estado_nuevo_id': nuevoIdEstado,
          'descripcion_detalle': desc,
        });
      } catch (auditError) {
        debugPrint(
          'SYNC AUDIT WARNING: No se pudo registrar la auditoría: $auditError',
        );
      }
    } catch (e) {
      throw Exception('Error al actualizar el estado de la orden: $e');
    }
  }

  // =================================================================
  // LECTURA: AUDITORÍA / HISTORIAL DE CAMBIOS DE ORDEN
  // =================================================================
  Future<List<AuditoriaOrdenModel>> obtenerAuditoriaOrden(
    String numOrden,
  ) async {
    try {
      final response = await _supabase
          .from('auditoria_ordenes')
          .select('''
            id_log, num_orden, id_usuario, fecha_cambio, descripcion_detalle,
            estado_anterior_id, estado_nuevo_id,
            profiles!id_usuario (nombre, apellido),
            estado_anterior:estado_orden!estado_anterior_id (nombre_estado),
            estado_nuevo:estado_orden!estado_nuevo_id (nombre_estado)
          ''')
          .eq('num_orden', numOrden)
          .order('fecha_cambio', ascending: false);

      return (response as List<dynamic>)
          .map(
            (json) =>
                AuditoriaOrdenModel.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Error al obtener la auditoría de la orden: $e');
    }
  }

  // =================================================================
  // ACTUALIZACIÓN DE ESTADO DE PAGO
  // =================================================================
  /// La tabla `orden` no cambió en el schema nuevo. Este método se
  /// mantiene tal cual.
  Future<void> actualizarEstadoPago(
    String numOrden,
    int nuevoIdEstadoPago,
  ) async {
    try {
      await _supabase
          .from('orden')
          .update({'id_estado_pago': nuevoIdEstadoPago})
          .eq('num_orden', numOrden);
    } catch (e) {
      throw Exception('Error al actualizar el pago de la orden: $e');
    }
  }

  // =================================================================
  // CREACIÓN DE ORDEN DESDE DRAFT
  // =================================================================
  Future<void> crearOrdenDesdeDraft(OrdenDraft draft) async {
    // 1. Validaciones de seguridad antes de enviar al backend
    if (draft.idCliente == null) throw Exception('El cliente es obligatorio');
    if (draft.fechaEntrega == null) {
      throw Exception('La fecha de entrega es obligatoria');
    }
    if (draft.items.isEmpty) {
      throw Exception('La orden debe tener al menos un ítem');
    }

    // =================================================================
    // 2. SUBIR IMAGEN A SUPABASE STORAGE (Si existe)
    // =================================================================
    String? imagenUrl;
    if (draft.imagenBytes != null && draft.imagenNombre != null) {
      try {
        // Creamos un nombre de archivo único para evitar sobreescrituras
        final extension = draft.imagenNombre!.split('.').last;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final rutaArchivo = 'modelo/modelo_$timestamp.$extension';

        // Subimos los bytes al bucket llamado 'imagenes_ordenes'
        await _supabase.storage
            .from('fichas_tecnicas')
            .uploadBinary(rutaArchivo, draft.imagenBytes!);

        // Obtenemos la URL pública para guardarla en la base de datos
        imagenUrl = _supabase.storage
            .from('fichas_tecnicas')
            .getPublicUrl(rutaArchivo);
      } catch (e) {
        throw Exception('Error al subir la imagen del modelo: $e');
      }
    }

    // =================================================================
    // 3. MAPEO DEL PAYLOAD PARA EL RPC
    // =================================================================
    final params = {
      'p_id_cliente': draft.idCliente,
      'p_fecha_entrega': draft.fechaEntrega!.toIso8601String().split('T')[0],

      // Pasamos la URL generada en el paso anterior (o null si no subió nada)
      'p_imagen_modelo': imagenUrl,

      // Conectamos también el campo de descripción/notas que el usuario escribe
      'p_notas_adicionales': draft.descripcion.trim().isNotEmpty
          ? draft.descripcion.trim()
          : null,

      'p_prioridad': draft.prioridad.name,
      'p_anticipo': draft.anticipo,
      'p_metodo_pago': draft.metodoPago,

      'p_items': draft.items.map((item) {
        return {
          'id_conjunto': item.idConjunto,
          'id_plantilla': item.idPlantilla,
          'precio_unitario': item.precioUnitario,
          'tallas': item.tallas
              .where((t) => t.cantidad > 0)
              .map((t) => {'id_talla': t.idTalla, 'cantidad': t.cantidad})
              .toList(),
        };
      }).toList(),
    };

    // =================================================================
    // 4. LLAMADA A LA BASE DE DATOS
    // =================================================================
    try {
      final response = await _supabase.rpc(
        'crear_orden_completa',
        params: params,
      );
      debugPrint('Orden creada con éxito. ID: $response');
    } catch (e) {
      debugPrint('Error al crear la orden desde el service: $e');
      rethrow;
    }
  }

  // =================================================================
  // AGREGAR ÍTEMS A UNA ORDEN EXISTENTE — STUB (pendiente)
  // =================================================================
  /// Pendiente de implementación. Mismas dependencias que
  /// crearOrdenDesdeDraft. Se reescribirá para insertar nuevos
  /// detalle_orden + detalle_orden_talla y recalcular costo_total.
  Future<void> agregarItemsAOrden({
    required String numOrden,
    required List<Map<String, dynamic>> nuevosItems,
  }) async {
    throw UnimplementedError(
      'agregarItemsAOrden está pendiente de migración al schema nuevo. '
      'Se implementa junto con crearOrdenDesdeDraft cuando estén disponibles '
      'los campos de precio en BD y la RPC.',
    );
  }

  // =================================================================
  // CÁLCULO DE MATERIALES — OUT OF SCOPE (rebanada vertical siguiente)
  // =================================================================
  /// El cálculo de materiales depende de iterar las plantillas del draft
  /// (incluyendo las que vienen dentro de conjuntos vía conjunto_plantilla)
  /// y consultar receta_material por cada una. Es trabajo de varios días
  /// y está listado como out-of-scope para esta rebanada — se aborda en
  /// una rebanada vertical siguiente. Por ahora devuelve lista vacía para
  /// no romper la UI que aún consume este método.
  @Deprecated(
    'Reescritura pendiente para schema nuevo. Out of scope en esta rebanada.',
  )
  Future<List<OrdenMaterialRequerido>> calcularMaterialesNecesarios(
    List<dynamic> productosDraft,
  ) async {
    return [];
  }

  // =================================================================
  // CÁLCULO DE PRECIOS SUGERIDOS — OUT OF SCOPE
  // =================================================================
  /// Mismo razonamiento que calcularMaterialesNecesarios. En el schema
  /// nuevo, el precio sale directo de plantilla_prenda.precio_plantilla
  /// y conjunto.precio_conjunto (no se calcula desde insumos en el front).
  /// Por ahora devuelve los productos sin cambios para no romper la UI.
  @Deprecated(
    'Reescritura pendiente para schema nuevo. Out of scope en esta rebanada.',
  )
  Future<List<OrdenProductoItem>> calcularPreciosSugeridos(
    List<OrdenProductoItem> productosDraft,
  ) async {
    return productosDraft;
  }
}
