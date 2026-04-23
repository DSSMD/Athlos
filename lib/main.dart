// ============================================================================
// main.dart
// Ubicación: lib/main.dart
//
// @denshel: cambios sobre tu versión:
//   - Se agrega InactivityDetector envolviendo MaterialApp.router (SCRUM-58)
//   - Se asigna scaffoldMessengerKey para mostrar el snackbar "Sesión expirada"
//   - Se escucha authStateProvider para activar/desactivar el timer según sesión
//   - Tu lógica de Supabase, dotenv y router queda intacta
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/router/app_router.dart';
import 'core/inactivity/inactivity_detector.dart';
import 'core/inactivity/session_expired_snackbar.dart';
import 'presentation/providers/auth_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargamos las variables de entorno de forma segura
  await dotenv.load(fileName: ".env");

  // Inicializamos Supabase usando las variables protegidas
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const ProviderScope(child: MyApp()));
}

// Cambiamos StatelessWidget por ConsumerWidget para poder leer a Riverpod
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos y obtenemos la configuración de GoRouter que creamos
    final router = ref.watch(goRouterProvider);

    // SCRUM-58: escuchamos el estado de autenticación para activar el timer
    // solo cuando hay sesión. Si no hay sesión (ej: en /login), el timer
    // no corre para no gastar recursos.
    final authAsync = ref.watch(authStateProvider);
    final isLoggedIn = authAsync.value?.session != null;

    // SCRUM-58: envolvemos la app con InactivityDetector. Al vencerse el
    // timeout de 30 minutos, se llama signOut() y se muestra un snackbar.
    // El router de Denshel reacciona solo al signOut y redirige a /login.
    return InactivityDetector(
      enabled: isLoggedIn,
      onInactive: () async {
        await Supabase.instance.client.auth.signOut();
        SessionExpiredSnackbar.show();
      },
      child: MaterialApp.router(
        title: 'Athlos Workspace',
        debugShowCheckedModeBanner: false,

        // Key global para mostrar snackbars desde fuera del árbol normal
        // (ej: cuando el InactivityDetector dispara el logout automático).
        scaffoldMessengerKey: rootScaffoldMessengerKey,

        // Conectamos el motor de go_router a nuestra aplicación
        routerConfig: router,

        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          fontFamily: 'Montserrat',
        ),
      ),
    );
  }
}
