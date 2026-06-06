import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart'; // NECESARIO PARA EL ESCUDO

import 'core/router/app_router.dart';
import 'core/inactivity/inactivity_detector.dart';
import 'core/inactivity/session_expired_snackbar.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/widgets/shared/no_internet_overlay.dart';
import 'presentation/providers/connectivity_provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

// 1. MANEJADOR EN SEGUNDO PLANO
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print("🔔 Alerta recibida en segundo plano: ${message.notification?.title}");
}

// 2. FILTRO DE NOTIFICACIONES (ESCUDO)
void _filtrarYMostrarNotificacion(RemoteMessage message) {
  final user = Supabase.instance.client.auth.currentUser;
  final idDestino = message.data['id_usuario']; // ID que viene en el JSON

  // Lógica:
  // Si el mensaje tiene id_usuario (personal) y no es el mio, lo ignoro.
  // Si es null (Admin/Global), lo dejo pasar.
  if (idDestino != null && user != null && idDestino.toString() != user.id) {
    print("🚫 Notificación ignorada: Era para otro usuario.");
    return;
  }

  print("✅ Notificación aceptada para: ${user?.id ?? 'Admin/Global'}");
}

// 3. CONFIGURACIÓN CON ESCUDO PARA EVITAR BUCLES
Future<void> _configurarNotificaciones() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await FirebaseMessaging.instance.requestPermission();

    // Configurar listener de mensajes (AQUÍ ESTÁ LA FILTRACIÓN)
    FirebaseMessaging.onMessage.listen((message) {
      _filtrarYMostrarNotificacion(message);
    });

    // SUSCRIPCIÓN GLOBAL (Solo una vez)
    if (prefs.getBool('sub_global') != true) {
      await FirebaseMessaging.instance.subscribeToTopic('jefes_produccion');
      await prefs.setBool('sub_global', true);
      print("✅ Suscripción global activada.");
    }

    String? fcmToken = await FirebaseMessaging.instance.getToken();

    // Escuchar cambios de autenticación
    // Escuchar cambios de autenticación
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final user = data.session?.user;
      if (user != null) {
        // Suscripción personalizada
        String topic = 'user_${user.id.replaceAll('-', '')}';

        if (prefs.getBool('sub_$topic') != true) {
          await FirebaseMessaging.instance.subscribeToTopic(topic);
          await prefs.setBool('sub_$topic', true);
        }

        // ... dentro del listener de auth ...
        // 🔥 CAMBIO CRÍTICO: Usamos .update() en lugar de .upsert()
        // Esto solo toca el fcm_token y no toca el resto de columnas.
        if (fcmToken != null) {
          try {
            await Supabase.instance.client
                .from('profiles')
                .update({'fcm_token': fcmToken})
                .eq('id', user.id);
            print("✅ Token actualizado en Supabase.");
          } catch (e) {
            print("⚠️ Error al actualizar token: $e");
          }
        }
      }
    });
  } catch (e) {
    print("⚠️ Error en notificaciones: $e");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await initializeDateFormatting('es_ES', null);

  // Llamamos a la configuración sin esperar (para no bloquear UI)
  _configurarNotificaciones();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    if (authAsync.isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    if (authAsync.hasError) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: Text("Error: ${authAsync.error}"))),
      );
    }

    final router = ref.watch(goRouterProvider);
    final isLoggedIn = authAsync.value?.session != null;
    final hasInternet = ref.watch(isConnectedProvider);

    return InactivityDetector(
      enabled: isLoggedIn,
      onInactive: () async {
        await Supabase.instance.client.auth.signOut();
        SessionExpiredSnackbar.show();
      },
      child: MaterialApp.router(
        title: 'Athlos Workspace',
        debugShowCheckedModeBanner: false,
        scaffoldMessengerKey: rootScaffoldMessengerKey,
        routerConfig: router,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('es', 'ES'), Locale('en', 'US')],
        locale: const Locale('es', 'ES'),
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          fontFamily: 'Montserrat',
        ),
        builder: (context, child) {
          return Stack(
            children: [
              child!,
              if (!hasInternet)
                Positioned.fill(
                  child: NoInternetOverlay(
                    onRetry: () => ref
                        .read(isConnectedProvider.notifier)
                        .checkConnectionManual(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
