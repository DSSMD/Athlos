// ============================================================================
// main_layout.dart
// Ubicación: lib/presentation/layouts/main_layout.dart
// Descripción: Carcasa responsiva de la aplicación.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/auth_service.dart';
import '../pages/registro_orden_page.dart';
import '../pages/usuarios_page.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'athlos_sidebar.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  bool _sidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(navigationIndexProvider);
    final userRole = ref.watch(userRoleProvider);

    final List<_NavItem> allNavItems = [
      _NavItem(
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        label: 'Dashboard',
        section: SidebarSection.principal,
        page: const Center(child: Text('Dashboard - Resumen de Producción')),
        roles: ['admin', 'super_admin', 'produccion', 'ventas'],
      ),
      _NavItem(
        icon: Icons.precision_manufacturing_outlined,
        selectedIcon: Icons.precision_manufacturing,
        label: 'Órdenes',
        section: SidebarSection.operaciones,
        page: const RegistroOrdenPage(),
        roles: ['admin', 'super_admin', 'ventas'],
      ),
      _NavItem(
        icon: Icons.inventory_2_outlined,
        selectedIcon: Icons.inventory_2,
        label: 'Inventario',
        section: SidebarSection.operaciones,
        page: const Center(child: Text('Inventario - Telas e Insumos')),
        roles: ['admin', 'super_admin', 'produccion'],
      ),
      _NavItem(
        icon: Icons.factory_outlined,
        selectedIcon: Icons.factory,
        label: 'Producción',
        section: SidebarSection.operaciones,
        page: const Center(child: Text('Producción - Lotes')),
        roles: ['admin', 'super_admin', 'produccion'],
      ),
      _NavItem(
        icon: Icons.people_alt_outlined,
        selectedIcon: Icons.people_alt,
        label: 'Clientes',
        section: SidebarSection.comercial,
        page: const Center(child: Text('Clientes')),
        roles: ['admin', 'super_admin', 'ventas'],
      ),
      _NavItem(
        icon: Icons.payments_outlined,
        selectedIcon: Icons.payments,
        label: 'Pagos',
        section: SidebarSection.comercial,
        page: const Center(child: Text('Pagos')),
        roles: ['admin', 'super_admin'],
      ),
      _NavItem(
        icon: Icons.bar_chart_outlined,
        selectedIcon: Icons.bar_chart,
        label: 'Balance',
        section: SidebarSection.comercial,
        page: const Center(child: Text('Balance mensual')),
        roles: ['admin', 'super_admin'],
      ),
      _NavItem(
        icon: Icons.people_outlined,
        selectedIcon: Icons.people,
        label: 'Usuarios',
        section: SidebarSection.sistema,
        page: const UsuariosPage(),
        roles: ['admin', 'super_admin'],
      ),
      _NavItem(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: 'Configuración',
        section: SidebarSection.sistema,
        page: const Center(child: Text('Configuración')),
        roles: ['admin', 'super_admin'],
      ),
      _NavItem(
        icon: Icons.notifications_outlined,
        selectedIcon: Icons.notifications,
        label: 'Notificaciones',
        section: SidebarSection.sistema,
        page: const Center(child: Text('Notificaciones')),
        roles: ['admin', 'super_admin', 'produccion', 'ventas'],
      ),
    ];

    final navItems =
        allNavItems.where((item) => item.roles.contains(userRole)).toList();
    final safeIndex = selectedIndex >= navItems.length ? 0 : selectedIndex;

    final sidebarItems = navItems
        .map((n) => SidebarItem(
              icon: n.icon,
              selectedIcon: n.selectedIcon,
              label: n.label,
              section: n.section,
            ))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 800) {
            // DESKTOP
            return Row(
              children: [
                AthlosSidebar(
                  items: sidebarItems,
                  selectedIndex: safeIndex,
                  onItemSelected: (i) => ref
                      .read(navigationIndexProvider.notifier)
                      .changeIndex(i),
                  userName: 'Nombre Apellido',
                  userRole: _prettyRole(userRole),
                  onLogout: () => _handleLogout(context),
                  collapsed: _sidebarCollapsed,
                  onToggleCollapsed: () => setState(
                      () => _sidebarCollapsed = !_sidebarCollapsed),
                ),
                Expanded(child: navItems[safeIndex].page),
              ],
            );
          } else {
            // MOBILE
            return Scaffold(
              backgroundColor: AppColors.sidebarDark,
              body: Column(
                children: [
                  Container(
                    color: AppColors.sidebarDark,
                    child: SafeArea(
                      bottom: false,
                      child: const SizedBox.shrink(),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: AppColors.background,
                      child: navItems[safeIndex].page,
                    ),
                  ),
                ],
              ),
              bottomNavigationBar: _MobileBottomNav(
                navItems: navItems,
                safeIndex: safeIndex,
                onItemSelected: (i) => ref
                    .read(navigationIndexProvider.notifier)
                    .changeIndex(i),
                onLogout: () => _handleLogout(context),
              ),
            );
          }
        },
      ),
    );
  }

  String _prettyRole(String? role) {
    switch (role) {
      case 'super_admin':
        return 'Super Admin';
      case 'admin':
        return 'Administrador';
      case 'produccion':
        return 'Producción';
      case 'ventas':
        return 'Ventas';
      default:
        return '—';
    }
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

// ══════════════════════════════════════════════════════════════════════════════

class _MobileBottomNav extends StatelessWidget {
  const _MobileBottomNav({
    required this.navItems,
    required this.safeIndex,
    required this.onItemSelected,
    required this.onLogout,
  });

  final List<_NavItem> navItems;
  final int safeIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onLogout;

  static const int _bottomBarCount = 4;

  @override
  Widget build(BuildContext context) {
    final bottomItems = navItems.take(_bottomBarCount).toList();
    final moreItems = navItems.skip(_bottomBarCount).toList();

    final selectedIsInMore = safeIndex >= _bottomBarCount;
    final bottomNavCurrent = selectedIsInMore ? bottomItems.length : safeIndex;

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.sidebarDark,
      selectedItemColor: AppColors.primary500,
      unselectedItemColor: AppColors.neutral400,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      currentIndex: bottomNavCurrent.clamp(0, bottomItems.length),
      onTap: (i) {
        if (i < bottomItems.length) {
          onItemSelected(i);
        } else {
          _showMoreMenu(context, moreItems);
        }
      },
      items: [
        ...bottomItems.map((item) => BottomNavigationBarItem(
              icon: Icon(item.icon),
              activeIcon: Icon(item.selectedIcon),
              label: item.label,
            )),
        if (moreItems.isNotEmpty)
          const BottomNavigationBarItem(
            icon: Icon(Icons.dehaze),
            activeIcon: Icon(Icons.dehaze),
            label: 'Más',
          ),
      ],
    );
  }

  void _showMoreMenu(BuildContext context, List<_NavItem> moreItems) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetCtx) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Text('Más', style: AppTypography.h3),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(sheetCtx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),
                ...moreItems.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final item = entry.value;
                  return ListTile(
                    leading: Icon(item.icon, color: AppColors.textPrimary),
                    title: Text(item.label, style: AppTypography.body),
                    trailing: const Icon(Icons.chevron_right,
                        color: AppColors.textMuted),
                    onTap: () {
                      Navigator.pop(sheetCtx);
                      onItemSelected(_bottomBarCount + idx);
                    },
                  );
                }),
                const Divider(height: 1, color: AppColors.border),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: Text(
                    'Cerrar sesión',
                    style: AppTypography.body.copyWith(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    onLogout();
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.section,
    required this.page,
    required this.roles,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final SidebarSection section;
  final Widget page;
  final List<String> roles;
}