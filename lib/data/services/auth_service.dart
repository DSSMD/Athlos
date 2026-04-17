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

  // Método para iniciar sesión con correo electrónico y contraseña
  // Este método utiliza la función de Supabase para autenticar al usuario con su correo electrónico y contraseña, y
  // devuelve la respuesta de autenticación que incluye el usuario autenticado y el token de acceso. Es importante
  // manejar correctamente el inicio de sesión para garantizar la seguridad y la privacidad del usuario, especialmente en
  // aplicaciones que manejan información sensible o que requieren autenticación para acceder a ciertas funcionalidades.
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

  // Método para cerrar sesión del usuario autenticado
  // Este método utiliza la función de Supabase para cerrar la sesión del usuario actual, lo que eliminará su sesión activa y
  // lo desconectará de la aplicación. Es importante manejar correctamente el cierre de sesión para garantizar la seguridad y
  // la privacidad del usuario, especialmente en aplicaciones que manejan información sensible o que requieren autenticación
  // para acceder a ciertas funcionalidades. Al cerrar sesión, el usuario deberá volver

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // Método para obtener el perfil del usuario autenticado, incluyendo su nombre y rol
  // Este método consulta la tabla "profiles" en Supabase para obtener el nombre del usuario y su rol, utilizando una relación con la tabla "roles" para obtener el nombre del rol

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

  // Método para enviar correo de recuperación de contraseña
  // Este método utiliza la función de Supabase para enviar un correo electrónico al usuario con un enlace para restablecer su contraseña.

  Future<void> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
    } catch (e) {
      debugPrint('Error enviando correo de recuperación: $e');
      rethrow;
    }
  }

  // Método para iniciar sesión con Google utilizando OAuth
  // Este método utiliza la función de Supabase para iniciar sesión con Google, lo que redirigirá al usuario a la página de autenticación de Google y
  // luego lo devolverá a la aplicación con su sesión activa si la autenticación es exitosa. Es importante manejar correctamente el inicio de sesión con
  // Google para garantizar la seguridad y la privacidad del usuario, especialmente en aplicaciones que manejan información sensible o que requieren
  // autenticación para acceder a ciertas funcionalidades. Al utilizar OAuth, se puede ofrecer a los usuarios una forma rápida y conveniente de iniciar
  // sesión sin tener que crear una cuenta específica para la aplicación.

  Future<void> signInWithGoogle() async {
    try {
      await _client.auth.signInWithOAuth(
        OAuthProvider.google,
        // Si es web, dejamos que Supabase maneje el localhost de origen.
        // Si es móvil/desktop, forzamos nuestro Deep Link.
        redirectTo: kIsWeb ? null : 'io.athlos.workspace://login-callback',
      );
    } catch (e) {
      debugPrint('Error en Google Sign-In: $e');
      throw Exception('No se pudo iniciar sesión con Google');
    }
  }
}
