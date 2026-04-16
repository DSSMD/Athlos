import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/auth_service.dart';

// Provider del servicio de autenticación
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Provider del estado de sesión en tiempo real
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Provider del rol del usuario usando Notifier (compatible con Riverpod 3)
class UserRoleNotifier extends Notifier<String> {
  @override
  String build() => 'admin'; // valor por defecto

  void setRole(String role) {
    state = role;
  }
}

final userRoleProvider = NotifierProvider<UserRoleNotifier, String>(
  UserRoleNotifier.new,
);

// Provider simple para saber si hay sesión activa
final isLoggedInProvider = Provider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser != null;
});