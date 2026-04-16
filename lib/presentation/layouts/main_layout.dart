import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';
import '../providers/auth_provider.dart';
import '../../data/services/auth_service.dart';
import '../pages/registro_orden_page.dart';
import '../pages/usuarios_page.dart';

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(navigationIndexProvider);
    final userRole = ref.watch(userRoleProvider);

    // Definir qué páginas ve cada rol
    final List<_NavItem> allNavItems = [
      _NavItem(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: 'Dashboard',
        page: const Center(child: Text('Dashboard - Resumen de Producción')),
        roles: ['admin', 'super_admin', 'produccion', 'ventas'],
      ),
      _NavItem(
        icon: Icons.precision_manufacturing_outlined,
        selectedIcon: Icons.precision_manufacturing,
        label: 'Taller',
        page: const RegistroOrdenPage(),
        roles: ['admin', 'super_admin', 'ventas'],
      ),
      _NavItem(
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2,
        label: 'Inventario',
        page: const Center(child: Text('Inventario - Telas e Insumos')),
        roles: ['admin', 'super_admin', 'produccion'],
      ),
      _NavItem(
        icon: Icons.attach_money_outlined,
        selectedIcon: Icons.attach_money,
        label: 'Finanzas',
        page: const Center(child: Text('Finanzas - Pagos y Balance')),
        roles: ['admin', 'super_admin'], // Producción NO ve esto
      ),
      _NavItem(
        icon: Icons.people_outlined,
        selectedIcon: Icons.people,
        label: 'Usuarios',
        page: const UsuariosPage(),
        roles: ['admin', 'super_admin'], // Solo admins ven esto
      ),
    ];

    // Filtrar según el rol del usuario
    final navItems = allNavItems
        .where((item) => item.roles.contains(userRole))
        .toList();

    // Asegurar que el índice no se pase del límite
    final safeIndex = selectedIndex >= navItems.length ? 0 : selectedIndex;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Athlos Workspace',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Botón de cerrar sesión
          IconButton(
            onPressed: () => _handleLogout(context),
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 800) {
            // VISTA DESKTOP
            bool isExtended = constraints.maxWidth >= 1000;

            return Row(
              children: [
                NavigationRail(
                  selectedIndex: safeIndex,
                  onDestinationSelected: (int index) {
                    ref
                        .read(navigationIndexProvider.notifier)
                        .changeIndex(index);
                  },
                  extended: isExtended,
                  labelType: isExtended
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  destinations: navItems
                      .map((item) => NavigationRailDestination(
                            icon: Icon(item.icon),
                            selectedIcon: Icon(item.selectedIcon),
                            label: Text(item.label),
                          ))
                      .toList(),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: navItems[safeIndex].page),
              ],
            );
          } else {
            // VISTA MOBILE
            return navItems[safeIndex].page;
          }
        },
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width < 800
          ? BottomNavigationBar(
              currentIndex: safeIndex,
              onTap: (index) {
                ref.read(navigationIndexProvider.notifier).changeIndex(index);
              },
              items: navItems
                  .map((item) => BottomNavigationBarItem(
                        icon: Icon(item.icon),
                        activeIcon: Icon(item.selectedIcon),
                        label: item.label,
                      ))
                  .toList(),
            )
          : null,
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar tu sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF0000),
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().signOut();
    }
  }
}

/// Modelo para los items de navegación con roles permitidos
class _NavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget page;
  final List<String> roles;

  _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.page,
    required this.roles,
  });
}