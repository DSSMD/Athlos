import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/services/user_service.dart';

// Provider del servicio
final userServiceProvider = Provider<UserService>((ref) {
  return UserService();
});

// Provider de la lista de usuarios
class UsersNotifier extends AsyncNotifier<List<UserModel>> {
  @override
  Future<List<UserModel>> build() async {
    return _fetchUsers();
  }

  Future<List<UserModel>> _fetchUsers() async {
    final service = ref.read(userServiceProvider);
    return service.getUsers();
  }

  // Recargar lista
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchUsers());
  }

  // Crear usuario
  Future<void> createUser({
    required String nombre,
    required String email,
    required String password,
    required String rol,
  }) async {
    final service = ref.read(userServiceProvider);
    await service.createUser(
      nombre: nombre,
      email: email,
      password: password,
      rol: rol,
    );
    await refresh();
  }

  // Actualizar usuario
  Future<void> updateUser({
    required String userId,
    required String nombre,
    required String email,
    required String rol,
  }) async {
    final service = ref.read(userServiceProvider);
    await service.updateUser(
      userId: userId,
      nombre: nombre,
      email: email,
      rol: rol,
    );
    await refresh();
  }

  // Toggle activar/desactivar
  Future<void> toggleActive(String userId, bool activo) async {
    final service = ref.read(userServiceProvider);
    await service.toggleUserActive(userId: userId, activo: activo);
    await refresh();
  }
}

final usersProvider =
    AsyncNotifierProvider<UsersNotifier, List<UserModel>>(
  UsersNotifier.new,
);
