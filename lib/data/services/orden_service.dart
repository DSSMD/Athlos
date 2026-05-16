import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:workspace/domain/models/detalle_orden_model.dart';
import 'package:workspace/domain/models/orden_model.dart';
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
            tiempo_procesamiento_estimado, imagen_modelo,
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
            tiempo_procesamiento_estimado, imagen_modelo,
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
  // ACTUALIZACIÓN DE ESTADO DE ORDEN
  // =================================================================
  /// La tabla `orden` no cambió en el schema nuevo. Este método se
  /// mantiene tal cual.
  Future<void> actualizarEstadoOrden(String numOrden, int nuevoIdEstado) async {
    try {
      await _supabase
          .from('orden')
          .update({'id_estado': nuevoIdEstado})
          .eq('num_orden', numOrden);
    } catch (e) {
      throw Exception('Error al actualizar el estado de la orden: $e');
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
  /// Crea una orden con sus detalles y tallas vía la RPC plpgsql
  /// `crear_orden_completa`. Transaccional del lado BD: si cualquier paso
  /// falla, se rollback el bloque entero.
  ///
  /// Retorna el `num_orden` (UUID como String) de la orden recién creada
  /// para que el caller pueda navegar al detalle si quiere.
  ///
  /// Lanza Exception con mensaje útil en caso de error de validación,
  /// FK violation, o cualquier error de Supabase.
  Future<String> crearOrdenDesdeDraft(OrdenDraft draft) async {
    // 1. Construir el payload de items
    final itemsPayload = draft.items.map((item) {
      return {
        'id_conjunto': item.tipoItem == TipoItem.conjunto
            ? item.idConjunto
            : null,
        'id_plantilla': item.tipoItem == TipoItem.plantilla
            ? item.idPlantilla
            : null,
        'precio_unitario': item.precioUnitario,
        'tallas': item.tallas
            .map((t) => {'id_talla': t.idTalla, 'cantidad': t.cantidad})
            .toList(),
      };
    }).toList();

    // 2. Postgres `date` espera 'YYYY-MM-DD'
    final fecha = draft.fechaEntrega;
    if (fecha == null) {
      throw Exception('La fecha de entrega es requerida');
    }
    final fechaStr =
        '${fecha.year.toString().padLeft(4, '0')}-'
        '${fecha.month.toString().padLeft(2, '0')}-'
        '${fecha.day.toString().padLeft(2, '0')}';

    // 3. notas_adicionales: enviar null si descripción está vacía
    final descTrim = draft.descripcion.trim();
    final notas = descTrim.isNotEmpty ? descTrim : null;

    // 4. Llamar a la RPC
    try {
      final result = await _supabase.rpc(
        'crear_orden_completa',
        params: {
          'p_fecha_entrega': fechaStr,
          'p_items': itemsPayload,
          'p_id_cliente': draft.idCliente,
          'p_notas_adicionales': notas,
          'p_imagen_modelo': null,
        },
      );

      return result.toString();
    } on PostgrestException catch (e) {
      throw Exception('Error al crear orden: ${e.message}');
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
