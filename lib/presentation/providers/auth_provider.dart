import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/auth_service.dart';

// Provider del servicio de autenticación (singleton)
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Provider que escucha el estado de la sesión en tiempo real
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Provider del rol del usuario actual
final userRoleProvider = FutureProvider<String?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return authService.getUserRole();
});

// Provider simple para saber si hay sesión activa
final isLoggedInProvider = Provider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser != null;
});
