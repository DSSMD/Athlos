// lib/presentation/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/services/auth_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    final prefs = await SharedPreferences.getInstance();

    // Bandera de control para evitar bucles
    final subKey = 'sub_user_${user.id}';
    final yaSuscrito = prefs.getBool(subKey) ?? false;

    if (!yaSuscrito) {
      // Suscripción al canal PRIVADO
      await FirebaseMessaging.instance.subscribeToTopic(
        'user_${user.id.replaceAll('-', '')}',
      );
      await prefs.setBool(subKey, true);
      print("✅ Suscripción exitosa a topic privado.");
    }

    // Suscripción al canal GLOBAL (solo una vez)
    if (rol == 'jefe_produccion') {
      final subJefeKey = 'sub_jefe';
      if (prefs.getBool(subJefeKey) != true) {
        await FirebaseMessaging.instance.subscribeToTopic('jefes_produccion');
        await prefs.setBool(subJefeKey, true);
      }
    }
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
