import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:workspace/presentation/layouts/athlos_sidebar.dart';
import 'package:workspace/presentation/pages/perfil/mi_perfil_page.dart';
import 'package:workspace/presentation/pages/produccion/dashboard/produccion_dashboard_page.dart';
import 'package:workspace/presentation/pages/admin/inventario/inventario_page.dart';
import 'package:workspace/presentation/pages/admin/conjuntos/conjuntos_page.dart';
import 'app_init_provider.dart';

// Importamos el cerebro y tus providers
import 'router_notifier.dart';
import '../../presentation/providers/auth_provider.dart';

// Ajusta estas rutas a tus pantallas
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/auth/setup_page.dart';
import '../../presentation/layouts/main_layout.dart';

import '../../presentation/pages/admin/usuarios_page.dart';
import '../../presentation/pages/cajas/orden_page.dart';
import '../../presentation/pages/produccion/produccion_page.dart';

import '../../presentation/pages/admin/clientes_page.dart';
import '../../presentation/pages/admin/dashboard/dashboard_page.dart';
import '../../presentation/pages/cajas/dashboard/ventas_dashboard_page.dart';
import '../../presentation/pages/admin/balance/balance_page.dart';
import '../../presentation/pages/admin/plantillas/plantillas_page.dart';
import '../../presentation/pages/produccion/scheduling/scheduling_page.dart';
import '../../presentation/widgets/notificaciones/notification_center.dart';

//import '../../presentation/models/cliente_mock.dart';
import '../../presentation/layouts/splash_screen_page.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    refreshListenable: notifier,

    // Arrancamos en loading para evaluar la sesión tranquilamente
    initialLocation: '/loading',

    redirect: (context, state) {
      final initAsync = ref.watch(appInitProvider);
      final needsSetupAsync = ref.watch(needsAdminSetupProvider);
      final authAsync = ref.read(authStateProvider);
      final path = state.uri.path;

      // Inicialización de la app o verificación de setup → splash siempre al arrancar
      if (initAsync.isLoading || needsSetupAsync.isLoading) {
        return path == '/loading' ? null : '/loading';
      }

      final needsSetup = needsSetupAsync.value ?? false;

      // Si se necesita configuración inicial, forzar la ruta /setup
      if (needsSetup) {
        return path == '/setup' ? null : '/setup';
      }

      // Si no necesita setup pero el usuario intenta ingresar a /setup, mandarlo a /login
      if (path == '/setup') {
        return '/login';
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
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(path: '/setup', builder: (context, state) => const SetupPage()),

      // ────────── RUTA GLOBAL DE PERFIL ──────────
      // Cualquier rol que haga context.push('/perfil') abrirá esta pantalla
      GoRoute(
        path: '/perfil',
        builder: (context, state) => const MiPerfilPage(),
      ),

      // ────────── ROL 1: ADMINISTRADOR (Páginas activas) ──────────
      GoRoute(
        path: '/admin',
        builder: (context, state) => MainLayout(
          pages: [
            const DashboardPage(), // 0. Dashboard
            const OrdenPage(),              // 1. Órdenes
            const InventarioPage(),         // 2. Inventario
            const ProduccionPage(),// 3. Producción
            const SchedulingPage(),         // 4. Scheduling
            const PlantillasPage(),         // 5. Plantillas
            const ConjuntosPage(),          // 6. Conjuntos
            const ClientesPage(),           // 7. Clientes
            const BalancePage(),             // 8. Balance Financiero
            const UsuariosPage(),           // 9. Usuarios
            const Padding(
              padding: EdgeInsets.all(16),
              child: NotificationCenter(),
            ), // 10. Avisos
          ],
          railDestinations: _buildRailFromRole('1'),
          bottomNavItems: _buildBottomFromRole('1'),
        ),
      ),

      // ────────── ROL 2: PRODUCCIÓN (5 Páginas) ──────────
      GoRoute(
        path: '/produccion',
        builder: (context, state) => MainLayout(
          pages: [
            const ProduccionDashboardPage(), // 0. Dashboard
            const InventarioPage(), // 1. Inventario
            const ProduccionPage(), // 2. Producción
            const SchedulingPage(), // 3. Scheduling
            const Padding(
              padding: EdgeInsets.all(16),
              child: NotificationCenter(),
            ), // 4. Avisos
          ],
          railDestinations: _buildRailFromRole('2'),
          bottomNavItems: _buildBottomFromRole('2'),
        ),
      ),

      // ────────── ROL 3: VENTAS (4 Páginas) ──────────
      GoRoute(
        path: '/ventas',
        builder: (context, state) => MainLayout(
          pages: [
            const VentasDashboardPage(), // 0. Dashboard
            const OrdenPage(), // 1. Órdenes
            const ClientesPage(), // 2. Clientes
            const Padding(
              padding: EdgeInsets.all(16),
              child: NotificationCenter(),
            ), // 3. Avisos
          ],
          railDestinations: _buildRailFromRole('3'),
          bottomNavItems: _buildBottomFromRole('3'),
        ),
      ),

      // ─────────── ROL 4: INVITADO (2 Páginas) ───────────
      GoRoute(
        path: '/invitado',
        builder: (context, state) => MainLayout(
          pages: [
            _buildPlaceholder('Dashboard'), // 0. Coincide con itemDashboard
            _buildPlaceholder(
              // 1. Coincide con itemEspera
              'Acceso en espera',
              subtitulo:
                  'Un administrador debe asignarte un área para comenzar.',
            ),
          ],
          railDestinations: _buildRailFromRole('4'),
          bottomNavItems: _buildBottomFromRole('4'),
        ),
      ),
    ],
  );
});

// Genera los destinos del Rail lateral automáticamente basado en el rol
List<NavigationRailDestination> _buildRailFromRole(String roleId) {
  final items = SidebarMenuConfig.itemsPorRol[roleId] ?? [];
  return items
      .map(
        (item) => NavigationRailDestination(
          icon: Icon(item.icon),
          selectedIcon: Icon(item.selectedIcon),
          label: Text(item.label),
        ),
      )
      .toList();
}

// Genera los ítems de la barra inferior automáticamente
List<BottomNavigationBarItem> _buildBottomFromRole(String roleId) {
  final items = SidebarMenuConfig.itemsPorRol[roleId] ?? [];
  return items
      .map(
        (item) => BottomNavigationBarItem(
          icon: Icon(item.icon),
          activeIcon: Icon(item.selectedIcon),
          label: item.label,
        ),
      )
      .toList();
}

// Pantalla genérica para secciones no terminadas
Widget _buildPlaceholder(
  String titulo, {
  String subtitulo = 'Esta sección está en desarrollo.',
}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.construction, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        Text(
          titulo,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            subtitulo,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      ],
    ),
  );
}
