import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'app_init_provider.dart';

// Importamos el cerebro y tus providers
import 'router_notifier.dart';
import '../../presentation/providers/auth_provider.dart';

// Ajusta estas rutas a tus pantallas
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/layouts/main_layout.dart';
import '../../presentation/pages/produccion/produccion_dashboard_page.dart';

import '../../presentation/pages/admin/usuarios_page.dart';
import '../../presentation/layouts/splash_screen_page.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    refreshListenable: notifier,

    // Arrancamos en loading para evaluar la sesión tranquilamente
    initialLocation: '/loading',

   redirect: (context, state) {
      final initAsync = ref.watch(appInitProvider);
      final authAsync = ref.read(authStateProvider);
      final path = state.uri.path;

      // Inicialización de la app → splash siempre al arrancar
      if (initAsync.isLoading) {
        return path == '/loading' ? null : '/loading';
      }

      // Permitir callback externo
      if (state.uri.toString().contains('login-callback')) return null;

      // Auth cargando → splash
      if (authAsync.isLoading) {
        return path == '/loading' ? null : '/loading';
      }

      final isLoggedIn = authAsync.value?.session != null;

      // No autenticado → login
      if (!isLoggedIn) {
        return path == '/login' ? null : '/login';
      }

      // Perfil
      final profileAsync = ref.read(userProfileProvider);

      if (profileAsync.isLoading || profileAsync.value == null) {
        return path == '/loading' ? null : '/loading';
      }

      final role = profileAsync.value?['id_rol']?.toString();

      // Redirección por rol
      if (path == '/login' || path == '/loading' || path == '/') {
        switch (role) {
          case '1':
            return '/admin';
          case '2':
            return '/produccion';
          case '3':
            return '/ventas';
          case '4':
            return '/invitado';
          default:
            return '/login';
        }
      }

      // Protección de rutas
      if (path.startsWith('/admin') && role != '1') {
        return '/produccion';
      }

      return null;
    },

    routes: [
      // RUTA DE CARGA TRANSITORIA
      GoRoute(
       path: '/loading',
        builder: (context, state) => const SplashScreenPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),

      // ROL 1: ADMINISTRADOR
      GoRoute(
        path: '/admin',
        builder: (context, state) => MainLayout(
          pages: const [
            Center(child: Text('Dashboard Admin General')),
            UsuariosPage(),
            Center(child: Text('Reportes Financieros')),
          ],
          railDestinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.dashboard),
              label: Text('Dashboard'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.people),
              label: Text('Usuarios'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.bar_chart),
              label: Text('Reportes'),
            ),
          ],
          bottomNavItems: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: 'Usuarios',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Reportes',
            ),
          ],
        ),
      ),

      // ROL 2: PRODUCCIÓN
      GoRoute(
        path: '/produccion',
        builder: (context, state) => MainLayout(
          pages: const [
            ProduccionDashboardPage(),
            Center(child: Text('Registro de Ordenes')),
            Center(child: Text('Inventario Telas')),
          ],
          railDestinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.precision_manufacturing),
              label: Text('Taller'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.assignment),
              label: Text('Órdenes'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.inventory_2),
              label: Text('Inventario'),
            ),
          ],
          bottomNavItems: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.precision_manufacturing),
              label: 'Taller',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment),
              label: 'Órdenes',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2),
              label: 'Inventario',
            ),
          ],
        ),
      ),

      // ROL 3: CAJAS / VENTAS
      GoRoute(
        path: '/ventas',
        builder: (context, state) => MainLayout(
          pages: const [
            Center(child: Text('Dashboard Cajas')),
            Center(child: Text('Punto de Venta (POS)')),
          ],
          railDestinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.point_of_sale),
              label: Text('Cajas'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.shopping_cart),
              label: Text('Ventas'),
            ),
          ],
          bottomNavItems: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.point_of_sale),
              label: 'Cajas',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Ventas',
            ),
          ],
        ),
      ),

      // ROL 4: INVITADO
      GoRoute(
        path: '/invitado',
        builder: (context, state) => MainLayout(
          pages: const [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hourglass_empty, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Acceso en espera. Un administrador debe asignarte un área.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
          railDestinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.hourglass_empty),
              label: Text('En Espera'),
            ),
          ],
          bottomNavItems: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.hourglass_empty),
              label: 'En Espera',
            ),
          ],
        ),
      ),
    ],
  );
});
