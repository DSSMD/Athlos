import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'dart:io'; // Se mantiene para Android/Desktop
import '../../presentation/providers/orden_form_provider.dart';
import 'package:http/http.dart' as http; // Necesario para leer la imagen en Web

class OrdenRepositoryImpl {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> guardarOrdenMultimodal(OrdenFormState formState) async {
    try {
      // --- PASO 0: Subir Imagen al Storage (Compatible con Web y Móvil) ---
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String path = 'modelos/$fileName';

      if (kIsWeb) {
        // Lógica para Navegador: Leemos los bytes desde el Blob URL
        final response = await http.get(Uri.parse(formState.imagePath!));
        final bytes = response.bodyBytes;
        await _supabase.storage
            .from('fichas_tecnicas')
            .uploadBinary(path, bytes);
      } else {
        // Lógica para Android/iOS: Usamos el archivo físico
        final file = File(formState.imagePath!);
        await _supabase.storage.from('fichas_tecnicas').upload(path, file);
      }

      final String publicUrl = _supabase.storage
          .from('fichas_tecnicas')
          .getPublicUrl(path);

      // --- PASO 1: Insertar en Tabla 'orden' ---
      final ordenResponse = await _supabase
          .from('orden')
          .insert({
            'id_cliente': formState.idCliente,
            'id_estado': 1,
            'fecha_entrega': formState.fechaEntrega!.toIso8601String(),
            'costo_total': 0,
          })
          .select('num_orden')
          .single();

      final String numOrdenId = ordenResponse['num_orden'];

      // --- PASO 2: Insertar en Tabla 'ficha_tecnica' ---
      await _supabase.from('ficha_tecnica').insert({
        'num_orden': numOrdenId,
        'imagen_modelo': publicUrl,
        'especificaciones': 'Modelo: ${formState.nombreModelo}',
      });

      // --- PASO 3: Insertar en Tabla 'desglose_tallas' ---
      // Asegúrate de que estos IDs (1, 2, 3, 4) existan en tu tabla 'tallas'
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
      debugPrint('❌ Error detallado: $e');
      throw Exception('Error en Supabase: $e');
    }
  }
}
