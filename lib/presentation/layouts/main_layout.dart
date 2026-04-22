// lib/presentation/layouts/main_layout.dart
// Layout principal que adapta su diseño según el tamaño de pantalla (Desktop vs Mobile)
// En Desktop, muestra una barra lateral oscura con el logo, menú de navegación y perfil
// En Mobile, muestra un AppBar con el logo y perfil, y un BottomNavigationBar para la navegación
// El contenido central cambia según la pestaña seleccionada en el menú de navegación
// IMPORTANTE: Este layout es el punto de entrada para la mayoría de las pantallas de la aplicación, y se encarga de manejar la navegación y la presentación general de la interfaz de usuario
// NOTA: Para una implementación real, se podrían agregar animaciones suaves al cambiar entre pestañas, y se podrían optimizar los widgets para mejorar el rendimiento en dispositivos móviles, especialmente en pantallas pequeñas.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';
import '../widgets/auth_profile_menu.dart';
import 'athlos_sidebar.dart';
//import 'package:supabase_flutter/supabase_flutter.dart';

// Creamos el Notifier que manejará el estado del Sidebar
class SidebarCollapsedNotifier extends Notifier<bool> {
  @override
  bool build() => false; // Estado inicial: expandido (false)

  // Función limpia para cambiar el estado
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
    final selectedIndex = ref.watch(navigationIndexProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // BREAKPOINT: 800px para separar Desktop de Mobile
        if (constraints.maxWidth >= 800) {
          bool isExtended = constraints.maxWidth >= 1000;
          return _buildDesktopLayout(context, ref, selectedIndex, isExtended);
        } else {
          return _buildMobileLayout(context, ref, selectedIndex);
        }
      },
    );
  }

  // DISEÑO DESKTOP (Nuevo Sidebar)
  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    int selectedIndex,
    bool isExtended,
  ) {
    // Convertimos temporalmente tus railDestinations antiguos al nuevo formato SidebarItem
    // NOTA: Lo ideal a futuro es que desde el router le pases directamente una lista de SidebarItem
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
        // Asignamos todo a "principal" por ahora para que compile y funcione
        section: SidebarSection.principal,
      );
    }).toList();

    return Scaffold(
      body: Row(
        children: [
          // TU NUEVO BARRA LATERAL ATHLOS
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

          // CONTENIDO CENTRAL
          Expanded(
            child: Container(
              color: Colors.grey.shade100, // Fondo claro para las páginas
              child: pages[selectedIndex],
            ),
          ),
        ],
      ),
    );
  }

  // DISEÑO MÓVIL
  Widget _buildMobileLayout(
    BuildContext context,
    WidgetRef ref,
    int selectedIndex,
  ) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          'ATHLOS',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // EL PERFIL EN MÓVIL (Arriba a la derecha)
          const AuthProfileMenu(isCollapsed: false, showFullInfo: false),
          const SizedBox(width: 10),
        ],
      ),
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        selectedItemColor: Colors.red.shade700,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          ref.read(navigationIndexProvider.notifier).changeIndex(index);
        },
        items: bottomNavItems,
      ),
    );
  }
}
