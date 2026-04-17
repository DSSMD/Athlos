// lib/presentation/providers/auth_provider.dart
// Provider para manejar la autenticación y el estado de sesión del usuario
// Este provider utiliza un servicio de autenticación (AuthService) que se encarga de interactuar con Supabase para iniciar sesión, cerrar sesión y obtener el rol del usuario
// El provider expone el estado de autenticación en tiempo real a través de un StreamProvider, así como el rol del usuario actual a través de un FutureProvider
// También incluye un provider simple para saber si hay una sesión activa o no, lo que facilita la lógica de navegación en la aplicación (por ejemplo, mostrar la pantalla de login o la pantalla principal según el estado de autenticación)
// IMPORTANTE: Este provider es fundamental para la seguridad y la gestión de usuarios en Athlos Workspace, y se utiliza en toda la aplicación para controlar el acceso a las diferentes funcionalidades según el estado de sesión y el rol del usuario.
// NOTA: Para una implementación real, se podrían agregar más funcionalidades al AuthService, como el registro de nuevos usuarios, la recuperación de contraseñas, la actualización de perfiles, etc., y el provider podría manejar esos casos también.

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
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (authState.value?.session == null) {
    return null;
  }
  final authService = ref.watch(authServiceProvider);
  return authService.getUserProfile();
});

// Provider simple para saber si hay sesión activa
final isLoggedInProvider = Provider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser != null;
});
