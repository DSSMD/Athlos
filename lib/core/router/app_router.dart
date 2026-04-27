import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Importamos el cerebro y tus providers
import 'router_notifier.dart';
import '../../presentation/providers/auth_provider.dart';

// Ajusta estas rutas a tus pantallas
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/layouts/main_layout.dart';
import '../../presentation/pages/produccion/produccion_dashboard_page.dart';

import '../../presentation/pages/admin/usuarios_page.dart';
import '../../presentation/pages/produccion/orden_page.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    refreshListenable: notifier,

    // Arrancamos en loading para evaluar la sesión tranquilamente
    initialLocation: '/loading',

    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      final isLoggedIn = authAsync.value?.session != null;
      final path = state.uri.path;

      // REGLA 1: SALVAVIDAS PARA GOOGLE (Permitimos el Deep Link)
      if (state.uri.toString().contains('login-callback')) return null;

      // REGLA 2: Sin sesión -> Al Login
      if (!isLoggedIn) {
        return path == '/login' ? null : '/login';
      }

      // REGLA 3: Leemos TU provider (que devuelve un Map)
      final profileAsync = ref.read(userProfileProvider);

      // REGLA 4: EL LIMBO (Si el perfil está cargando, mostramos la pantalla de carga)
      if (profileAsync.isLoading || profileAsync.value == null) {
        return path == '/loading' ? null : '/loading';
      }

      // Extraemos el rol del Map de tu provider
      final role = profileAsync.value?['id_rol']?.toString();

      // REGLA 5: Distribución según rol
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

      // (Opcional) Bloqueo de rutas en web
      if (path.startsWith('/admin') && role != '1') return '/produccion';

      return null;
    },

    routes: [
      // RUTA DE CARGA TRANSITORIA
      GoRoute(
        path: '/loading',
        builder: (context, state) => const Scaffold(
          backgroundColor: Color(0xFF0A0A0A),
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFFFF0000)),
          ),
        ),
      ),

      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(), // <-- Así de limpio
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
            Center(child: Text('Dashboard Cajas')), // Página 1: Dashboard
            OrdenesPage(), // Página 2: Tu nueva vista de Órdenes
          ],
          railDestinations: const [
            NavigationRailDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: Text('Inicio'),
            ),
            NavigationRailDestination(
              icon: Icon(Icons.assignment_outlined), // Ícono de lista/orden
              selectedIcon: Icon(Icons.assignment),
              label: Text('Órdenes'),
            ),
          ],
          bottomNavItems: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Inicio',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.assignment_outlined),
              activeIcon: Icon(Icons.assignment),
              label: 'Órdenes',
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
