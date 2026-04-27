import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:workspace/domain/models/orden_model.dart';
import '../../presentation/providers/orden_form_provider.dart'; // Importamos tu form state

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
        cliente (nom_cliente, apellido_cliente, num_telefono),
        estado_orden (nombre_estado),
        estado_pago (nombre_estado),
        ficha_tecnica (tipo_prenda (nombre_prenda)),
        desglose_tallas (cantidad)
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
  // CREACIÓN DE ORDEN MULTIMODAL (Rescatado y Adaptado)
  // =================================================================
  Future<void> crearOrdenMultimodal(OrdenFormState formState) async {
    try {
      String publicUrl = '';

      // --- PASO 0: Subir Imagen si existe ---
      if (formState.imagePath != null && formState.imagePath!.isNotEmpty) {
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final String path = 'modelos/$fileName';

        if (kIsWeb) {
          final response = await http.get(Uri.parse(formState.imagePath!));
          final bytes = response.bodyBytes;
          await _supabase.storage
              .from('fichas_tecnicas')
              .uploadBinary(path, bytes);
        } else {
          final file = File(formState.imagePath!);
          await _supabase.storage.from('fichas_tecnicas').upload(path, file);
        }

        publicUrl = _supabase.storage
            .from('fichas_tecnicas')
            .getPublicUrl(path);
      }

      // --- PASO 1: Insertar en Tabla 'orden' ---
      // IMPORTANTE: Asegúrate de que los IDs por defecto existan en tu BD (ej: 1 = Pendiente)
      final ordenResponse = await _supabase
          .from('orden')
          .insert({
            'id_cliente': formState.idCliente,
            'id_estado': 1, // Ej: 1 = Pendiente
            'id_estado_pago': 1, // Ej: 1 = No Pagado
            'fecha_entrega': formState.fechaEntrega!.toIso8601String(),
            'costo_total': 0, // Se actualizará después o se pide en el form
          })
          .select('num_orden')
          .single();

      final String numOrdenId = ordenResponse['num_orden'];

      // --- PASO 2: Insertar en Tabla 'ficha_tecnica' ---
      await _supabase.from('ficha_tecnica').insert({
        'num_orden': numOrdenId,
        // Si no hay imagen, mandamos null
        'imagen_modelo': publicUrl.isNotEmpty ? publicUrl : null,
        'especificaciones': 'Modelo: ${formState.nombreModelo}',
        'id_tipo_prenda': 1, // Reemplazar por el tipo real seleccionado
      });

      // --- PASO 3: Insertar en Tabla 'desglose_tallas' ---
      final Map<String, int> mapeoTallasBD = {'S': 1, 'M': 2, 'L': 3, 'XL': 4};
      List<Map<String, dynamic>> tallasParaInsertar = [];

      formState.tallas.forEach((nombreTalla, cantidad) {
        if (cantidad > 0) {
          tallasParaInsertar.add({
            'num_orden': numOrdenId,
            'id_talla': mapeoTallasBD[nombreTalla] ?? 1,
            'cantidad': cantidad,
          });
        }
      });

      if (tallasParaInsertar.isNotEmpty) {
        await _supabase.from('desglose_tallas').insert(tallasParaInsertar);
      }
    } catch (e) {
      debugPrint('❌ Error en creación de orden: $e');
      throw Exception('Error al guardar la orden completa: $e');
    }
  }

  /// Actualiza únicamente el estado de producción de una orden
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

  /// Actualiza únicamente el estado de pago de una orden
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
}
