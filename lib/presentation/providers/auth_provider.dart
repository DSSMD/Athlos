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

