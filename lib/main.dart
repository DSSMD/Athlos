import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';

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

// 🔥 NUEVA FUNCIÓN: Esto evita que la pantalla se quede en blanco
Future<void> _configurarNotificaciones() async {
  try {
    await FirebaseMessaging.instance.requestPermission();

    // Le volvemos a poner el timeout de 10 segundos para que no se congele
    // ... dentro de _configurarNotificaciones() ...
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // ESTA LÍNEA ES LA CLAVE
        await Supabase.instance.client.from('profiles').upsert({
          'id': user.id,
          'fcm_token':
              fcmToken, // Asegura que se actualice el token real del dispositivo
        });
        print("✅ Token sincronizado con Supabase: $fcmToken");
      }
    }

    await FirebaseMessaging.instance.subscribeToTopic('jefes_produccion');

    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && fcmToken != null) {
      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': fcmToken})
          .eq('id', user.id);
    }
  } catch (e) {
    print("⚠️ Error en inicialización de notificaciones: $e");
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A. INICIALIZAR FIREBASE (Sin bloqueos largos)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // B. INICIALIZAR SUPABASE Y ENTORNO
  await dotenv.load(fileName: ".env");
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await initializeDateFormatting('es_ES', null);

  // 🔥 LLAMAMOS A LA FUNCIÓN, PERO SIN EL "await" AL PRINCIPIO
  // Así la app arranca al instante y no se queda en blanco.
  _configurarNotificaciones();

  // C. ARRANCAR LA INTERFAZ
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
