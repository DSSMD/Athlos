import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'presentation/layouts/main_layout.dart';
import 'presentation/pages/login_page.dart';
import 'presentation/providers/auth_provider.dart';

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
      home: const AuthGate(),
    );
  }
}

/// AuthGate — Decide si mostrar Login o MainLayout
/// y obtiene el rol del usuario después del login
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _isLoggedIn = Supabase.instance.client.auth.currentSession != null;

    // Si ya hay sesión, obtener el rol
    if (_isLoggedIn) {
      _fetchUserRole();
    }

    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) {
        setState(() {
          _isLoggedIn = data.session != null;
        });
        if (data.session != null) {
          _fetchUserRole();
        }
      }
    });
  }

  // Obtener el rol del usuario y guardarlo en el provider
  Future<void> _fetchUserRole() async {
    final authService = ref.read(authServiceProvider);
    final role = await authService.getUserRole();
    if (role != null && mounted) {
      ref.read(userRoleProvider.notifier).setRole(role);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoggedIn) {
      return const MainLayout();
    } else {
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