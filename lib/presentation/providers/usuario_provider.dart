// lib/presentation/providers/usuario_provider.dart

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
    required int? idArea, 
  required double? tarifaPagoBase,
  }) async {
    final service = ref.read(usuarioServiceProvider);

    // 1.  EL TRUCO: Guardamos la lista de usuarios que está actualmente en pantalla
    final estadoAnterior = state;

    state = const AsyncValue.loading();

    try {
      await service.crearUsuario(
        nombre: nombre,
        apellido: apellido,
        email: email,
        password: password,
        telefono: telefono,
        rol: rol,
        idArea: idArea,
        tarifaPagoBase: tarifaPagoBase,
      );

      // Si sale bien, recargamos la lista desde la base de datos
      state = await AsyncValue.guard(() async {
        return _fetchUsuarios();
      });
    } catch (e) {
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
    int? idArea,
    double? tarifaPagoBase,
    // TODO (Permisos): Recibir required List<String> permisos, y pasarlos al Service.
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
        idArea: idArea,
        tarifaPagoBase: tarifaPagoBase,
      );
      return _fetchUsuarios();
    });
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ACCIÓN: Cambiar Estado (Activo/Inactivo rápido)
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> cambiarEstatus(UsuarioModel user) async {
    final service = ref.read(usuarioServiceProvider);

    state = await AsyncValue.guard(() async {
      await service.actualizarUsuario(
        user.id,
        nombre: user.name.split(' ').first,
        apellido: user.name.contains(' ') ? user.name.split(' ').last : '',
        telefono: user.phone,
        rol: user.role,
        activo: !user.status.toString().contains('activo'),
        idArea: user.idArea,
        tarifaPagoBase: user.tarifaPagoBase,
      );
      return _fetchUsuarios();
    });
  }
}

// ══════════════════════════════════════════════════════════════════════════
// PROVEEDOR DE CATÁLOGO DE ÁREAS
// ══════════════════════════════════════════════════════════════════════════
final areasProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = Supabase.instance.client;
  
  final response = await supabase
      .from('area_produccion')
      .select('id_area, nombre_area')
      .order('id_area', ascending: true);

  return List<Map<String, dynamic>>.from(response);
});
