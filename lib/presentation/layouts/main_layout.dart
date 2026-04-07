import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart'; // Importamos el provider

// 1. Cambiamos StatefulWidget por ConsumerWidget
class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  // 2. Agregamos WidgetRef para poder comunicarnos con Riverpod
  Widget build(BuildContext context, WidgetRef ref) {
    
    // 3. Escuchamos el estado global del índice
    final selectedIndex = ref.watch(navigationIndexProvider);

    // Pantallas de ejemplo
    final List<Widget> pages = [
      const Center(child: Text('Dashboard - Resumen de Producción')),
      const Center(child: Text('Taller - Control de Confección')),
      const Center(child: Text('Inventario - Telas e Insumos')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Athlos Workspace',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Breakpoint para Desktop: 800px
          if (constraints.maxWidth >= 800) {
            bool isExtended = constraints.maxWidth >= 1000;

            return Row(
              children: [
                NavigationRail(
                  // Usamos la variable de Riverpod
                  selectedIndex: selectedIndex, 
                  onDestinationSelected: (int index) {
                    // 4. Actualizamos el estado global en lugar de usar setState
                      ref.read(navigationIndexProvider.notifier).changeIndex(index);                  },
                  extended: isExtended,
                  labelType: isExtended
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.precision_manufacturing_outlined),
                      selectedIcon: Icon(Icons.precision_manufacturing),
                      label: Text('Taller'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.inventory_2_outlined),
                      selectedIcon: Icon(Icons.inventory_2),
                      label: Text('Inventario'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                // Mostramos la página según el índice de Riverpod
                Expanded(child: pages[selectedIndex]), 
              ],
            );
          } else {
            // VISTA MOBILE
            return pages[selectedIndex];
          }
        },
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width < 800
          ? BottomNavigationBar(
              // Usamos la variable de Riverpod
              currentIndex: selectedIndex, 
              onTap: (index) {
                // Actualizamos el estado global
                    ref.read(navigationIndexProvider.notifier).changeIndex(index);              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.dashboard_outlined),
                  activeIcon: Icon(Icons.dashboard),
                  label: 'Dashboard',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.precision_manufacturing_outlined),
                  activeIcon: Icon(Icons.precision_manufacturing),
                  label: 'Taller',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.inventory_2_outlined),
                  activeIcon: Icon(Icons.inventory_2),
                  label: 'Inventario',
                ),
              ],
            )
          : null,
    );
  }
}