// lib/presentation/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// 1. El Servicio de Auth
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// 2. Notifier para gestionar la lógica de autenticación y suscripciones
class AuthNotifier extends Notifier<AuthState?> {
  @override
  AuthState? build() {
    return null;
  }

  // Llama a esto DESPUÉS de hacer signInWithPassword en tu servicio
  Future<void> manejarLoginExitoso(User user, String rol) async {
    // Suscripción al canal PRIVADO
    await FirebaseMessaging.instance.subscribeToTopic('user_${user.id}');

    // Suscripción al canal GLOBAL si es jefe
    if (rol == 'jefe_produccion') {
      await FirebaseMessaging.instance.subscribeToTopic('jefes_produccion');
    }
    print("✅ Suscrito a temas de Firebase correctamente.");
  }

  Future<void> manejarLogout() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await FirebaseMessaging.instance.unsubscribeFromTopic('user_${user.id}');
      await FirebaseMessaging.instance.unsubscribeFromTopic('jefes_produccion');
    }
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState?>(() {
  return AuthNotifier();
});

// 3. Provider que escucha el estado de la sesión (Streams)
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// 4. Provider del perfil
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authState = ref.watch(authStateProvider);
  if (authState.value?.session == null) return null;

  final authService = ref.watch(authServiceProvider);
  return authService.getUserProfile();
});

final isLoggedInProvider = Provider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser != null;
});
