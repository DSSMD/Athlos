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
  final perfil = await authService.getUserProfile();

  if (perfil == null) {
    // Si el usuario está autenticado pero no tiene perfil en la BD, cerramos la sesión para limpiar el estado huérfano
    await authService.signOut();
    return null;
  }

  return perfil;
});

final isLoggedInProvider = Provider<bool>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.currentUser != null;
});

// Provider asíncrono para verificar si la base de datos necesita la cuenta de administrador inicial.
// IMPORTANTE: Usa RPC (función con SECURITY DEFINER) para poder ser llamada sin sesión activa.
// Las políticas RLS de SELECT en profiles requieren un usuario autenticado, por lo que
// una query directa .from('profiles') siempre devolvería null para el rol anon,
// causando que la pantalla de setup aparezca aunque ya existan administradores.
//
// REQUIERE en Supabase (ejecutar en SQL Editor):
//   CREATE OR REPLACE FUNCTION public.tiene_administrador()
//   RETURNS boolean LANGUAGE sql SECURITY DEFINER SET search_path = public AS $$
//     SELECT EXISTS (SELECT 1 FROM public.profiles WHERE id_rol = 1 LIMIT 1);
//   $$;
//   GRANT EXECUTE ON FUNCTION public.tiene_administrador() TO anon;
final needsAdminSetupProvider = FutureProvider<bool>((ref) async {
  try {
    final client = Supabase.instance.client;

    // Llamamos a la función RPC que puede ejecutarse sin autenticación
    // porque tiene SECURITY DEFINER y el rol anon tiene EXECUTE concedido.
    final bool tieneAdmin = await client.rpc('tiene_administrador');

    // Si ya existe al menos un administrador, NO necesitamos setup
    return !tieneAdmin;
  } catch (e) {
    // En caso de error (función no creada, sin conexión, etc.)
    // devolvemos false por defecto para no bloquear el arranque normal.
    return false;
  }
});

