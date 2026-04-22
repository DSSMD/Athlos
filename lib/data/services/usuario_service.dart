import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/usuario_model.dart';

class UsuarioService {
  final SupabaseClient _supabase;

  UsuarioService(this._supabase);

  // ══════════════════════════════════════════════════════════════════════════
  // LECTURA
  // ══════════════════════════════════════════════════════════════════════════
  Future<List<UsuarioModel>> obtenerUsuarios() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('''
        id, nombre, apellido, email, telefono, activo, ultimo_acceso, roles (nombre_rol)
      ''')
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((item) => UsuarioModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al obtener usuarios: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CREACIÓN
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> crearUsuario({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
    required String? telefono,
    required UserRole rol,
  }) async {
    try {
      final session = _supabase.auth.currentSession;

      // Le "gritamos" a la función en la nube de Supabase que haga el trabajo
      final response = await _supabase.functions.invoke(
        'admin_crear_usuario', // El nombre que le daremos a tu Edge Function
        headers: {
          if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
        },
        body: {
          'email': email,
          'password': password,
          'nombre': nombre,
          'apellido': apellido,
          'telefono': telefono,
          'id_rol': _roleToInt(rol),
        },
      );

      // Verificamos si la función nos respondió con éxito (código 200 o 201)
      if (response.status != 200 && response.status != 201) {
        throw Exception('Error del servidor: ${response.data}');
      }
    } catch (e) {
      throw Exception('Error al crear usuario: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ACTUALIZACIÓN
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> actualizarUsuario(
    String id, {
    required String nombre,
    required String apellido,
    required String? telefono,
    required UserRole rol,
    required bool activo,
  }) async {
    try {
      // Esto sí lo podemos hacer directo desde Flutter porque somos Admin
      // y tenemos permiso en el RLS de la tabla profiles.
      await _supabase
          .from('profiles')
          .update({
            'nombre': nombre,
            'apellido': apellido,
            'telefono': telefono,
            'id_rol': _roleToInt(rol),
            'activo': activo,
          })
          .eq('id', id);
    } catch (e) {
      throw Exception('Error al actualizar usuario: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  int _roleToInt(UserRole role) {
    switch (role) {
      case UserRole.administrador:
        return 1;
      case UserRole.produccion:
        return 2;
      case UserRole.cajas:
        return 3;
      case UserRole.invitado:
        return 4;
    }
  }
}
