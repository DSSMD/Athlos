// lib/presentation/layouts/main_layout.dart
// Layout principal que adapta su diseño según el tamaño de pantalla (Desktop vs Mobile)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/navigation_provider.dart';
import '../theme/app_colors.dart';
import '../theme/breakpoints.dart';
import '../widgets/shared/more_options_sheet.dart';
import 'athlos_sidebar.dart';

// Creamos el Notifier que manejará el estado del Sidebar
class SidebarCollapsedNotifier extends Notifier<bool> {
  @override
  bool build() => false; // Estado inicial: expandido (false)

  void toggle() {
    state = !state;
  }
}

// Declaramos el provider usando la nueva sintaxis
final sidebarCollapsedProvider =
    NotifierProvider<SidebarCollapsedNotifier, bool>(
      SidebarCollapsedNotifier.new,
    );

class MainLayout extends ConsumerWidget {
  final List<Widget> pages;
  final List<NavigationRailDestination> railDestinations;
  final List<BottomNavigationBarItem> bottomNavItems;

  const MainLayout({
    super.key,
    required this.pages,
    required this.railDestinations,
    required this.bottomNavItems,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rawIndex = ref.watch(navigationIndexProvider);

    final safeIndex = (rawIndex >= pages.length) ? 0 : rawIndex;

    // Migrated to AppBreakpoints.mobile (1100). Was previously: 800/1000.
    if (context.isMobile) {
      return _buildMobileLayout(context, ref, safeIndex);
    }
    // Desktop: sidebar extendido si la ventana es wide (>=1300).
    final isExtended = context.isWide;
    return _buildDesktopLayout(context, ref, safeIndex, isExtended);
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    int selectedIndex,
    bool isExtended,
  ) {
    final isManuallyCollapsed = ref.watch(sidebarCollapsedProvider);
    final shouldCollapse = !isExtended || isManuallyCollapsed;
    final sidebarItems = railDestinations.map((dest) {
      return SidebarItem(
        icon: (dest.icon as Icon).icon ?? Icons.circle,
        selectedIcon:
            (dest.selectedIcon as Icon?)?.icon ??
            (dest.icon as Icon).icon ??
            Icons.circle,
        label: (dest.label as Text).data ?? '',
        section: SidebarSection.principal,
      );
    }).toList();

    return Scaffold(
      body: Row(
        children: [
          AthlosSidebar(
            items: sidebarItems,
            selectedIndex: selectedIndex,
            collapsed: shouldCollapse,
            onItemSelected: (index) {
              ref.read(navigationIndexProvider.notifier).changeIndex(index);
            },
            onToggleCollapsed: () {
              ref.read(sidebarCollapsedProvider.notifier).toggle();
            },
          ),
          Expanded(
            child: Container(
              color: Colors.grey.shade100,
              child: pages[selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  // DISEÑO MÓVIL — sin AppBar global; cada page maneja su propio header.
  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    int selectedIndex,
  ) {
    final totalItems = bottomNavItems.length;
    final useMoreTab = totalItems > 5;

    final visibleItems = <BottomNavigationBarItem>[];
    if (useMoreTab) {
      // Primeros 4 items + "Más"
      visibleItems.addAll(bottomNavItems.take(4));
      visibleItems.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.more_horiz),
          label: 'Más',
        ),
      );
    } else {
      visibleItems.addAll(bottomNavItems);
    }

    final currentIndex = useMoreTab && selectedIndex >= 4 ? 4 : selectedIndex;

    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: AppColors.primary500,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (useMoreTab && index == 4) {
            _showMoreSheet(context, ref);
          } else {
            ref.read(navigationIndexProvider.notifier).changeIndex(index);
          }
        },
        items: visibleItems,
      ),
    );
  }

  void _showMoreSheet(BuildContext context, WidgetRef ref) {
    final hiddenItems = bottomNavItems.skip(4).toList();
    final options = <MoreOption>[];

    for (var i = 0; i < hiddenItems.length; i++) {
      final item = hiddenItems[i];
      final originalIndex = i + 4;
      final label = item.label ?? '';
      final iconData = (item.icon is Icon)
          ? (item.icon as Icon).icon ?? Icons.circle
          : Icons.circle;

      options.add(
        MoreOption(
          icon: iconData,
          iconBgColor: _colorForLabel(label),
          label: label,
          description: _descriptionForLabel(label),
          originalIndex: originalIndex,
        ),
      );
    }

    showMoreOptionsSheet(
      context: context,
      options: options,
      onSelected: (index) {
        ref.read(navigationIndexProvider.notifier).changeIndex(index);
      },
    );
  }

  String _descriptionForLabel(String label) {
    switch (label) {
      case 'Clientes':
        return 'Gestión y contactos';
      case 'Pagos':
        return 'Registro y cobros';
      case 'Balance':
        return 'Resumen financiero';
      case 'Usuarios':
        return 'Gestión y roles';
      case 'Configuración':
        return 'Backup y sistema';
      case 'Avisos':
      case 'Notificaciones':
        return 'Alertas y urgencias';
      default:
        return '';
    }
  }

  Color _colorForLabel(String label) {
    switch (label) {
      case 'Clientes':
        return AppColors.primary500;
      case 'Pagos':
        return AppColors.success;
      case 'Balance':
        return AppColors.info;
      case 'Usuarios':
        return AppColors.neutral600;
      case 'Configuración':
        return AppColors.warning;
      case 'Avisos':
      case 'Notificaciones':
        return AppColors.primary500;
      default:
        return AppColors.neutral600;
    }
  }
}
