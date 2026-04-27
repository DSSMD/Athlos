// ignore_for_file: avoid_print

import 'package:supabase_flutter/supabase_flutter.dart';
//import 'package:flutter/foundation.dart';
//import 'dart:io';
//import 'package:http/http.dart' as http;
import 'package:workspace/domain/models/orden_model.dart';
import 'package:workspace/presentation/components/ordenes/orden_draft.dart';

class OrdenService {
  final SupabaseClient _supabase;

  OrdenService(this._supabase);

  // =================================================================
  // LECTURA DE ÓRDENES (Actualizado con Deep Joins)
  // =================================================================
  Future<List<OrdenModel>> obtenerOrdenes() async {
    try {
      final response = await _supabase
          .from('orden')
          .select('''
        num_orden, id_cliente, id_estado, id_estado_pago,
        fecha_orden, fecha_entrega, costo_total, notas_adicionales,
        cliente (nom_cliente, apellido_cliente, num_telefono, ci_cliente, email, direccion),
        estado_orden (nombre_estado),
        estado_pago (nombre_estado),
        ficha_tecnica (imagen_modelo, tipo_prenda (nombre_prenda)), 
        desglose_tallas (cantidad, tallas (nombre_talla), tipo_prenda (nombre_prenda)) 
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
  // ACTUALIZACIÓN DE ESTADO DE ORDEN (Nuevo Método)
  // =================================================================
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
  // ACTUALIZACIÓN DE ESTADO DE PAGO (Nuevo Método)
  // =================================================================
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
  // CREACIÓN DE ORDEN DESDE DRAFT (Nivel Industrial)
  // =================================================================
  Future<void> crearOrdenDesdeDraft(OrdenDraft draft) async {
    try {
      // 1. Validaciones de cimientos
      if (draft.idCliente == null) {
        throw Exception('El cliente es obligatorio');
      }
      if (draft.fechaEntrega == null) {
        throw Exception('La fecha es obligatoria');
      }
      if (draft.productos.isEmpty) {
        throw Exception('Debe agregar al menos un producto con su talla');
      }

      // ---------------------------------------------------------
      // NUEVO PASO: Cálculo de Costo Total basado en Recetas
      // ---------------------------------------------------------
      double costoTotalCalculado = 0;

      for (var p in draft.productos) {
        // Obtenemos el costo de materiales para este TIPO de prenda
        double costoMateriales = await _obtenerCostoMaterialesPorTipo(
          p.idTipoPrenda!,
        );

        // --- Lógica de Negocio ---
        double manoDeObra =
            25.0; // Valor base por prenda (puedes traerlo de BD luego)
        double margenUtilidad = 1.4; // Ganancia del 40%

        double precioUnitarioSugerido =
            (costoMateriales + manoDeObra) * margenUtilidad;
        costoTotalCalculado += precioUnitarioSugerido * p.cantidad;
      }

      // Unimos notas y prioridad
      String notasCompletas =
          'Prioridad: ${draft.prioridad.name.toUpperCase()}\n';
      if (draft.descripcion.isNotEmpty) {
        notasCompletas += 'Notas: ${draft.descripcion}\n';
      }

      // ---------------------------------------------------------
      // PASO 1.5: Subir Imagen al Storage (Bucket: fichas_tecnicas)
      // ---------------------------------------------------------
      String? urlImagen;
      if (draft.imagenBytes != null) {
        // Generamos un nombre único usando la fecha actual
        final fileName = draft.imagenNombre ?? 'modelo.jpg';

        // Apuntamos a la carpeta 'modelos' dentro del bucket
        final path =
            'modelos/${DateTime.now().millisecondsSinceEpoch}_$fileName';

        // Subimos los bytes al bucket 'fichas_tecnicas'
        await _supabase.storage
            .from('fichas_tecnicas')
            .uploadBinary(path, draft.imagenBytes!);

        // Obtenemos la URL pública para guardarla en la base de datos
        urlImagen = _supabase.storage
            .from('fichas_tecnicas')
            .getPublicUrl(path);
      }

      // ---------------------------------------------------------
      // PASO 2: Creación de la Cabecera (Tabla 'orden')
      // ---------------------------------------------------------
      final ordenResponse = await _supabase
          .from('orden')
          .insert({
            'id_cliente': draft.idCliente,
            'id_estado': 1,
            'id_estado_pago': draft.anticipo > 0 ? 2 : 1,
            'fecha_entrega': draft.fechaEntrega?.toIso8601String(),
            'costo_total': costoTotalCalculado, // <--- ¡YA NO ES CERO! 🔥
            'notas_adicionales': notasCompletas,
          })
          .select('num_orden')
          .single();

      final String numOrdenId = ordenResponse['num_orden'];

      // ---------------------------------------------------------
      // PASO 3: Definición del Producto (Tabla 'ficha_tecnica')
      // ---------------------------------------------------------
      // Como ahora podemos agregar múltiples prendas (Polera, Pantalón),
      // extraemos los IDs únicos de las prendas que seleccionó el usuario
      final prendasUnicas = draft.productos
          .map((p) => p.idTipoPrenda)
          .toSet()
          .whereType<int>(); // Filtra nulos por seguridad

      List<Map<String, dynamic>> fichasAInsertar = [];
      for (var idPrenda in prendasUnicas) {
        fichasAInsertar.add({
          'num_orden': numOrdenId,
          'id_tipo_prenda': idPrenda,
          'imagen_modelo':
              urlImagen, // <--- AQUÍ VINCULAMOS LA URL DE LA IMAGEN
          'especificaciones': 'Prenda generada desde la orden de venta',
        });
      }

      // Hacemos un Insert múltiple si hay prendas
      if (fichasAInsertar.isNotEmpty) {
        await _supabase.from('ficha_tecnica').insert(fichasAInsertar);
      }

      // ---------------------------------------------------------
      // PASO 4: Escandallo de Cantidades (Tabla 'desglose_tallas')
      // ---------------------------------------------------------
      List<Map<String, dynamic>> tallasAInsertar = [];

      for (var producto in draft.productos) {
        tallasAInsertar.add({
          'num_orden': numOrdenId,
          'id_tipo_prenda': producto.idTipoPrenda,
          'id_talla': producto.idTalla,
          'cantidad': producto.cantidad,
        });
      }

      // Insert Múltiple masivo para todas las tallas
      if (tallasAInsertar.isNotEmpty) {
        await _supabase.from('desglose_tallas').insert(tallasAInsertar);
      }

      // --- PASO EXTRA: Si hay anticipo, lo guardamos en la tabla de pagos ---
      // Si tienes la tabla, descomenta esto; si no, déjalo comentado.
      /*
      if (draft.anticipo > 0) {
        await _supabase.from('pago_cliente').insert({
          'id_cliente': draft.idCliente,
          'id_orden': numOrdenId,
          'monto': draft.anticipo,
          'metodo_pago': draft.metodoPago,
        });
      }
      */

      // EL PASO 5 SE EJECUTARÁ AUTOMÁTICAMENTE GRACIAS A TU TRIGGER EN BD 🔥
    } catch (e) {
      throw Exception('Error al guardar la orden en BD: $e');
    }
  }

  // =================================================================
  // FUNCIÓN AUXILIAR: Obtener Costo Total de Materiales por Tipo de Prenda
  // =================================================================
  Future<double> _obtenerCostoMaterialesPorTipo(int idTipoPrenda) async {
    try {
      // Buscamos la receta de CUALQUIER ficha técnica que sea de este tipo
      // (asumimos que la receta es estándar para el tipo de prenda)
      final response = await _supabase
          .from('receta_material')
          .select('cantidad_estandar, insumo:id_insumo(costo_unitario)')
          .eq('ficha_tecnica.id_tipo_prenda', idTipoPrenda);

      // ignore: unnecessary_null_comparison
      if (response == null || (response as List).isEmpty) return 0.0;

      double total = 0;
      for (var row in response) {
        double cant = (row['cantidad_estandar'] as num).toDouble();
        double costo = (row['insumo']['costo_unitario'] as num).toDouble();
        total += (cant * costo);
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  // =================================================================
  // CÁLCULO DE MATERIALES REQUERIDOS (Nueva Función para Calculadora)
  // =================================================================
  Future<List<OrdenMaterialRequerido>> calcularMaterialesNecesarios(
    List<dynamic> productosDraft,
  ) async {
    try {
      print('--- INICIANDO CALCULADORA (VERSIÓN TOP-DOWN) ---');

      final idsPrendas = productosDraft
          .map((p) => p.idTipoPrenda)
          .where((id) => id != null)
          .toSet()
          .toList();

      if (idsPrendas.isEmpty) return [];

      // 1. Consulta TOP-DOWN: Pedimos la ficha y anidamos sus hijos (receta -> insumo)
      final response = await _supabase
          .from('ficha_tecnica')
          .select('''
            id_tipo_prenda,
            receta_material (
              cantidad_estandar,
              insumo ( nombre, stock_actual, unidad_medida (abreviatura) )
            )
          ''')
          .filter(
            'id_tipo_prenda',
            'in',
            idsPrendas,
          ); // Filtro directo a la tabla principal

      print(
        'Respuesta BD: ${response.length} fichas técnicas encontradas para estos IDs.',
      );

      Map<String, OrdenMaterialRequerido> consolidado = {};
      Set<int> prendasYaProcesadas = {};

      // 2. Procesamos la respuesta
      for (var ficha in response) {
        final idTipoPrenda = ficha['id_tipo_prenda'] as int;

        // Extraemos la lista de recetas (si no tiene, devuelve lista vacía)
        final recetas = ficha['receta_material'] as List<dynamic>? ?? [];

        // Si esta ficha específica está vacía (quizás es una orden sin procesar), la ignoramos
        if (recetas.isEmpty) continue;

        // Si ya encontramos una plantilla con materiales para esta prenda, saltamos las demás
        if (prendasYaProcesadas.contains(idTipoPrenda)) continue;
        prendasYaProcesadas.add(idTipoPrenda);

        print(
          '✅ Ficha válida encontrada para prenda ID $idTipoPrenda con ${recetas.length} materiales.',
        );

        // Buscamos cuántas prendas de este tipo pide el usuario en el formulario
        final cantidadPedida = productosDraft
            .where((p) => p.idTipoPrenda == idTipoPrenda)
            .fold(0, (prev, p) => prev + (p.cantidad as int));

        // 3. Sumamos los materiales al consolidado global
        for (var row in recetas) {
          final insumo = row['insumo'] ?? {};
          final nombre = insumo['nombre'] ?? 'Insumo desconocido';
          final stock = (insumo['stock_actual'] ?? 0 as num).toDouble();
          final unidad = insumo['unidad_medida']?['abreviatura'] ?? 'u.';
          final cantEstandar = (row['cantidad_estandar'] ?? 0 as num)
              .toDouble();

          final requeridoTotal = cantEstandar * cantidadPedida;

          if (consolidado.containsKey(nombre)) {
            final actual = consolidado[nombre]!;
            consolidado[nombre] = actual.copyWith(
              requerido: actual.requerido + requeridoTotal,
            );
          } else {
            consolidado[nombre] = OrdenMaterialRequerido(
              material: nombre,
              requerido: requeridoTotal,
              stockActual: stock,
              unidad: unidad,
            );
          }
        }
      }

      if (consolidado.isEmpty) {
        print(
          '⚠️ AVISO: Las fichas se encontraron, pero ninguna tenía materiales asignados en "receta_material".',
        );
      } else {
        print(
          'Cálculo final exitoso: ${consolidado.length} materiales requeridos.',
        );
      }

      return consolidado.values.toList();
    } catch (e, stacktrace) {
      print('🚨 ERROR EN CALCULADORA: $e');
      print(stacktrace);
      return [];
    }
  }

  // =================================================================
  // CÁLCULO DE PRECIOS SUGERIDOS (Nueva Función para Calculadora)
  // =================================================================
  Future<List<OrdenProductoItem>> calcularPreciosSugeridos(
    List<OrdenProductoItem> productosDraft,
  ) async {
    List<OrdenProductoItem> productosActualizados = [];

    for (var p in productosDraft) {
      if (p.idTipoPrenda == null) {
        productosActualizados.add(p);
        continue;
      }

      try {
        final response = await _supabase
            .from('ficha_tecnica')
            .select(
              'receta_material(cantidad_estandar, insumo(costo_unitario))',
            )
            .eq('id_tipo_prenda', p.idTipoPrenda!)
            .limit(1)
            .maybeSingle();

        double costoMateriales = 0;

        if (response != null && response['receta_material'] != null) {
          for (var rm in (response['receta_material'] as List)) {
            double cant = (rm['cantidad_estandar'] ?? 0).toDouble();
            double costoUnitario = (rm['insumo']?['costo_unitario'] ?? 0)
                .toDouble();
            costoMateriales += (cant * costoUnitario);
          }
        }

        double manoDeObra = 25.0;
        double margenGanancia = 1.40;

        // Precio sugerido por unidad
        double precioSugerido = (costoMateriales + manoDeObra) * margenGanancia;

        // Actualizamos el producto con su nuevo precio unitario
        productosActualizados.add(p.copyWith(precioUnitario: precioSugerido));
      } catch (e) {
        print('Error calculando precio para prenda ${p.idTipoPrenda}: $e');
        productosActualizados.add(p);
      }
    }

    return productosActualizados;
  }
}
