import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'presentation/layouts/main_layout.dart';
import 'presentation/pages/login_page.dart'; // ← NUEVO: import del login

Future<void> main() async {
  // Aseguramos que los bindings de Flutter estén listos
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializamos el cliente de Supabase (Reemplaza con tus credenciales de Athlos)
  await Supabase.initialize(
    url: 'https://txnmhtoczfgjdwdptrfl.supabase.co',
    anonKey: 'sb_publishable_hZCE_7ITTUx2teLWHqB25A_j_6VCmoZ',
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Athlos Workspace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        fontFamily: 'Montserrat', 
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 32, 
            fontWeight: FontWeight.bold,
            fontFamily: 'Montserrat',
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontFamily: 'Montserrat',
          ),
        ),
      ),
      // CAMBIO: Antes era MainLayout(), ahora es AuthGate()
      // AuthGate decide si mostrar Login o MainLayout según la sesión
      home: const AuthGate(), 
    );
  }
}

// ============================================
// NUEVO: AuthGate — Decide qué pantalla mostrar
// Si hay sesión activa → MainLayout (lo de Den)
// Si no hay sesión → LoginPage (lo tuyo)
// ============================================
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    // Verificar si ya hay una sesión activa al abrir la app
    _isLoggedIn = Supabase.instance.client.auth.currentSession != null;

    // Escuchar cambios de sesión (login, logout, token refresh)
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          _isLoggedIn = data.session != null;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn) {
      // Si hay sesión → muestra el layout de Den tal cual
      return const MainLayout();
    } else {
      // Si no hay sesión → muestra tu login
      return LoginPage(
        onLoginSuccess: () {
          setState(() {
            _isLoggedIn = true;
          });
        },
      );
    }
  }
}