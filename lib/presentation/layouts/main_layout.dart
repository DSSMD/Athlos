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
import '../widgets/auth_profile_menu.dart'; // El widget que creamos antes
//import 'package:supabase_flutter/supabase_flutter.dart';

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

  // DISEÑO DESKTOP (Sidebar Oscura)
  Widget _buildDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    int selectedIndex,
    bool isExtended,
  ) {
    return Scaffold(
      body: Row(
        children: [
          // BARRA LATERAL
          Container(
            width: isExtended ? 260 : 80,
            color: const Color(0xFF121212), // Fondo negro
            child: Column(
              children: [
                const SizedBox(height: 40),
                // 1. LOGO ATHLOS (Arriba)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: isExtended
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.flash_on,
                        color: Colors.red,
                        size: 30,
                      ), // Tu Logo
                      if (isExtended) ...[
                        const SizedBox(width: 10),
                        const Text(
                          'ATHLOS',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // 2. MENÚ DE NAVEGACIÓN (Centro)
                Expanded(
                  child: NavigationRail(
                    backgroundColor: Colors
                        .transparent, // Importante: Transparente para ver el fondo del Container
                    unselectedIconTheme: const IconThemeData(
                      color: Colors.white60,
                    ),
                    selectedIconTheme: const IconThemeData(color: Colors.red),
                    unselectedLabelTextStyle: const TextStyle(
                      color: Colors.white60,
                    ),
                    selectedLabelTextStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    selectedIndex: selectedIndex,
                    extended: isExtended,
                    onDestinationSelected: (index) {
                      ref
                          .read(navigationIndexProvider.notifier)
                          .changeIndex(index);
                    },
                    destinations: railDestinations,
                  ),
                ),

                // 3. PERFIL Y CIERRE DE SESIÓN (Abajo)
                const Divider(color: Colors.white24, indent: 20, endIndent: 20),
                AuthProfileMenu(
                  isCollapsed: !isExtended,
                ), // El perfil con nombre y rol
                const SizedBox(height: 10),
              ],
            ),
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
