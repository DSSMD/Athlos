import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class UserService {
  final SupabaseClient _client = Supabase.instance.client;

  // Obtener todos los usuarios
  Future<List<UserModel>> getUsers() async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      return (response as List)
          .map((user) => UserModel.fromMap(user))
          .toList();
    } catch (e) {
      // Si la tabla no existe aún, devolver lista vacía
      return [];
    }
  }

  // Crear usuario nuevo (auth + profile)
  Future<void> createUser({
    required String nombre,
    required String email,
    required String password,
    required String rol,
  }) async {
    // 1. Crear en Supabase Auth
    final authResponse = await _client.auth.admin.createUser(
      AdminUserAttributes(
        email: email,
        password: password,
        emailConfirm: true,
      ),
    );

    if (authResponse.user != null) {
      // 2. Crear perfil en la tabla profiles
      await _client.from('profiles').upsert({
        'id': authResponse.user!.id,
        'nombre': nombre,
        'email': email,
        'rol': rol,
        'activo': true,
      });
    }
  }

  // Actualizar usuario existente
  Future<void> updateUser({
    required String userId,
    required String nombre,
    required String email,
    required String rol,
  }) async {
    await _client.from('profiles').update({
      'nombre': nombre,
      'email': email,
      'rol': rol,
    }).eq('id', userId);
  }

  // Activar/desactivar usuario (toggle)
  Future<void> toggleUserActive({
    required String userId,
    required bool activo,
  }) async {
    await _client.from('profiles').update({
      'activo': activo,
    }).eq('id', userId);
  }

  // Eliminar usuario
  Future<void> deleteUser(String userId) async {
    await _client.from('profiles').delete().eq('id', userId);
  }
}
