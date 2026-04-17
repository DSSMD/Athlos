// main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'presentation/layouts/main_layout.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/navigation_provider.dart'; // Asegúrate de importar esto

import 'presentation/pages/produccion/produccion_dashboard_page.dart'; // Importamos la nueva página de producción

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        fontFamily: 'Montserrat',
      ),
      home: const AuthGate(), 
    );
  }
}

// ============================================
// PUERTA 1: Verifica si hay sesión
// ============================================
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authStateAsync = ref.watch(authStateProvider);

    return authStateAsync.when(
      data: (authState) {
        if (authState.session != null) {
          return const RoleRouter();
        } else {
          return LoginPage(onLoginSuccess: () {});
        }
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error de Auth: $error')),
      ),
    );
  }
}

// ============================================
// PUERTA 2: Verifica el rol y redirige
// ============================================
class RoleRouter extends ConsumerWidget {
  const RoleRouter({super.key});

 @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    ref.listen<AsyncValue<Map<String, dynamic>?>>(userProfileProvider, (previous, next) {
      
      final prevRole = previous?.value?['id_rol']?.toString();
      final nextRole = next.value?['id_rol']?.toString();

      if (prevRole != nextRole) {
        ref.read(navigationIndexProvider.notifier).changeIndex(0);
      }
    });

    return profileAsync.when(
      data: (profile) {
        final role = profile?['id_rol']?.toString();
        switch (role) {
          case '1': // Administrador (Ve Todo)
            return MainLayout(
              pages: const [
                Center(child: Text('Dashboard Admin General')),
                Center(child: Text('Gestión de Usuarios')),
                Center(child: Text('Reportes Financieros')),
              ],
              railDestinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
                NavigationRailDestination(icon: Icon(Icons.people), label: Text('Usuarios')),
                NavigationRailDestination(icon: Icon(Icons.bar_chart), label: Text('Reportes')),
              ],
              bottomNavItems: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
                BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Usuarios'),
                BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reportes'),
              ],
            );
          
          case '2': // Producción
            return MainLayout(
              pages: const [
                ProduccionDashboardPage(),
                Center(child: Text('Registro de Ordenes')), // Aquí iría const RegistroOrdenPage()
                Center(child: Text('Inventario Telas')),
              ],
              railDestinations: const [
                NavigationRailDestination(icon: Icon(Icons.precision_manufacturing), label: Text('Taller')),
                NavigationRailDestination(icon: Icon(Icons.assignment), label: Text('Órdenes')),
                NavigationRailDestination(icon: Icon(Icons.inventory_2), label: Text('Inventario')),
              ],
              bottomNavItems: const [
                BottomNavigationBarItem(icon: Icon(Icons.precision_manufacturing), label: 'Taller'),
                BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Órdenes'),
                BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Inventario'),
              ],
            );

          case '3': // Cajas / Ventas
            return MainLayout(
              pages: const [
                Center(child: Text('Dashboard Cajas')),
                Center(child: Text('Punto de Venta (POS)')),
              ],
              railDestinations: const [
                NavigationRailDestination(icon: Icon(Icons.point_of_sale), label: Text('Cajas')),
                NavigationRailDestination(icon: Icon(Icons.shopping_cart), label: Text('Ventas')),
              ],
              bottomNavItems: const [
                BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Cajas'),
                BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Ventas'),
              ],
            );

          default: // MUY IMPORTANTE: Si el rol no es 1, 2 o 3
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error: Rol no válido o no asignado ($role)'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Supabase.instance.client.auth.signOut(),
                      child: const Text('Cerrar Sesión'),
                    )
                  ],
                ),
              ),
            );
        }
      },
      // ESTO ES LO QUE FALTABA:
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error obteniendo perfil: $error')),
      ),
    );
  }
}