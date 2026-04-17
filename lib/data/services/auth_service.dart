// services/auth_service.dart
// Servicio de autenticación que interactúa con Supabase para manejar el inicio de sesión, cierre de sesión y obtener el rol del usuario
// Este servicio es utilizado por el AuthProvider para exponer la funcionalidad de autenticación a través de providers en la aplicación
// IMPORTANTE: Este servicio es fundamental para la seguridad y la gestión de usuarios en Athlos Workspace, y se utiliza en toda la aplicación 
// para controlar el acceso a las diferentes funcionalidades según el estado de sesión y el rol del usuario.

// NOTA: Para una implementación real, se podrían agregar más funcionalidades al AuthService, como el registro de nuevos usuarios, 
// la recuperación de contraseñas, la actualización de perfiles, etc., y el provider podría manejar esos casos también.

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final response = await _client
          .from('profiles')
          .select('''
            nombre,
            id_rol,
            roles (
              nombre_rol
            )
          ''') 
          .eq('id', user.id)
          .single();

      return response;
    } catch (e) {
      debugPrint('Error obteniendo el perfil del usuario: $e');
      return null;
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('Error enviando correo de recuperación: $e');
      rethrow; 
    }
  }
}
