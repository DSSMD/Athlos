import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/usuario_service.dart';
import '../../domain/models/usuario_model.dart';

// 1. Proveedor del Servicio
final usuarioServiceProvider = Provider<UsuarioService>((ref) {
  return UsuarioService(Supabase.instance.client);
});

// 2. Proveedor de la Lista de Usuarios (AsyncNotifier)
final usuariosProvider =
    AsyncNotifierProvider<UsuariosNotifier, List<UsuarioModel>>(() {
      return UsuariosNotifier();
    });

class UsuariosNotifier extends AsyncNotifier<List<UsuarioModel>> {
  @override
  Future<List<UsuarioModel>> build() async {
    return _fetchUsuarios();
  }

  // Lógica interna para obtener los datos
  Future<List<UsuarioModel>> _fetchUsuarios() async {
    final service = ref.read(usuarioServiceProvider);
    return await service.obtenerUsuarios();
  }

  // Refrescar manualmente
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchUsuarios());
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ACCIÓN: Crear Usuario
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> crearUsuario({
    required String nombre,
    required String apellido,
    required String email,
    required String password,
    required String? telefono,
    required UserRole rol,
  }) async {final service = ref.read(usuarioServiceProvider);

    // 1.  EL TRUCO: Guardamos la lista de usuarios que está actualmente en pantalla
    final estadoAnterior = state; 

    // Ponemos el estado en carga mientras trabaja
    state = const AsyncValue.loading();

    try {
      // Intentamos crear el usuario
      await service.crearUsuario(
        nombre: nombre,
        apellido: apellido,
        email: email,
        password: password,
        telefono: telefono,
        rol: rol,
      );
      
      // Si sale bien, recargamos la lista desde la base de datos
      state = await AsyncValue.guard(() async {
        return _fetchUsuarios();
      });

    } catch (e, stack) {
      // 2. 💡 LA CORRECCIÓN: Si falla, NO ponemos estado de error. 
      // Restauramos la tabla normal que guardamos al principio.
      state = estadoAnterior; 
      
      // 3. Escupimos el error hacia el Frontend para que tu SnackBar lo atrape
      rethrow; 
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ACCIÓN: Actualizar Usuario
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> actualizarUsuario(
    String id, {
    required String nombre,
    required String apellido,
    required String? telefono,
    required UserRole rol,
    required bool activo,
  }) async {
    final service = ref.read(usuarioServiceProvider);

    state = await AsyncValue.guard(() async {
      await service.actualizarUsuario(
        id,
        nombre: nombre,
        apellido: apellido,
        telefono: telefono,
        rol: rol,
        activo: activo,
      );
      // Tras actualizar, devolvemos la lista fresca
      return _fetchUsuarios();
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ACCIÓN: Cambiar Estado (Activo/Inactivo rápido)
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> cambiarEstatus(UsuarioModel user) async {
    final service = ref.read(usuarioServiceProvider);

    state = await AsyncValue.guard(() async {
      // Usamos el método de actualizar pero solo mandamos el cambio de 'activo'
      await service.actualizarUsuario(
        user.id,
        nombre: user.name.split(' ').first, // Pequeño parseo para el service
        apellido: user.name.contains(' ') ? user.name.split(' ').last : '',
        telefono: user.phone,
        rol: user.role,
        activo: !user.status.toString().contains(
          'activo',
        ), // Invertimos el estado
      );
      return _fetchUsuarios();
    });
  }
}
