import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/tipo_prenda_model.dart';

class CatalogoService {
  final _supabase = Supabase.instance.client;

  Future<List<TipoPrendaModel>> obtenerTiposPrenda() async {
    try {
      final response = await _supabase
          .from('tipo_prenda')
          .select('id_tipo_prenda, nombre_prenda')
          .order('nombre_prenda');

      return (response as List)
          .map((json) => TipoPrendaModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener tipos de prenda: $e');
    }
  }
}