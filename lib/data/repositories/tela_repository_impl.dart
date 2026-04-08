import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/tela_repository.dart';
import '../models/tela_model.dart';

class TelaRepositoryImpl implements TelaRepository {
  // Inyectamos el cliente de Supabase
  final SupabaseClient _supabaseClient;

  TelaRepositoryImpl(this._supabaseClient);

  @override
  Future<List<TelaModel>> getTelas() async {
    try {
      // Consulta a la tabla 'telas' en Supabase
      final response = await _supabaseClient.from('telas').select();
      
      // Convertimos la lista de JSONs a una lista de TelaModel
      return (response as List<dynamic>)
          .map((item) => TelaModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener el inventario de telas: $e');
    }
  }
}