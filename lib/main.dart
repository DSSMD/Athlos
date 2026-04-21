import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargamos las variables de entorno de forma segura
  await dotenv.load(fileName: ".env");

  // Inicializamos Supabase usando las variables protegidas
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// Cambiamos StatelessWidget por ConsumerWidget para poder leer a Riverpod
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos y obtenemos la configuración de GoRouter que creamos
    final router = ref.watch(goRouterProvider);

    // Cambiamos MaterialApp por MaterialApp.router
    return MaterialApp.router(
      title: 'Athlos Workspace',
      debugShowCheckedModeBanner: false,
      
      // Conectamos el motor de go_router a nuestra aplicación
      routerConfig: router,
      
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        fontFamily: 'Montserrat',
      ),
    );
  }
}