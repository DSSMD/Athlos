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
      // 💡 CAMBIO: Agregamos el Deep Join para traer datos del trabajador y su área
      final response = await _supabase
          .from('profiles')
          .select('''
            id, nombre, apellido, email, telefono, activo, ultimo_acceso, 
            roles (nombre_rol),
            trabajadores (
              id_trabajador, 
              tarifa_pago_base, 
              fecha_contratacion, 
              id_area,
              area_produccion (nombre_area)
            )
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
    int? idArea,
    double? tarifaPagoBase,
  }) async {
    try {
      final session = _supabase.auth.currentSession;
      
      final response = await _supabase.functions.invoke(
        'admin_crear_usuario', 
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
          // 👇 Mandamos los datos laborales directamente al servidor
          'id_area': idArea,
          'tarifa_pago_base': tarifaPagoBase, 
        },
      );

      if (response.status != 200 && response.status != 201) {
        throw Exception('Error del servidor: ${response.data}');
      }
      
      // ¡Y listo! Ya no hacemos el insert desde Flutter.
      // El servidor se encarga de crear el auth, el profile y el trabajador de forma segura.

    } on FunctionException catch (e) {
      rethrow;
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
    // 💡 CAMBIO: Nuevos parámetros opcionales
    int? idArea,
    double? tarifaPagoBase,
  }) async {
    try {
      // 1. Actualizamos el Profile (Datos Personales / Acceso)
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

      // 2. Actualizamos o Creamos el registro de Trabajador (Datos Laborales)
      if (idArea != null) {
        // Verificamos si ya existe como trabajador
        final checkTrabajador = await _supabase
            .from('trabajadores')
            .select('id_trabajador')
            .eq('id_usuario', id)
            .maybeSingle();

        if (checkTrabajador != null) {
          // Si ya era trabajador, solo actualizamos su área/tarifa
          await _supabase.from('trabajadores').update({
            'id_area': idArea,
            'tarifa_pago_base': tarifaPagoBase ?? 0.00,
          }).eq('id_usuario', id);
        } else {
          // Si antes no era trabajador (ej. pasó de Administrador a Producción), lo insertamos
          await _supabase.from('trabajadores').insert({
            'id_usuario': id,
            'id_area': idArea,
            'tarifa_pago_base': tarifaPagoBase ?? 0.00,
          });
        }
      }
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