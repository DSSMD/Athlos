import 'package:flutter/material.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // Pantallas de ejemplo para cumplir el PR (Navegable)
  final List<Widget> _pages = [
    const Center(child: Text('Dashboard - Resumen de Producción')),
    const Center(child: Text('Taller - Control de Confección')),
    const Center(child: Text('Inventario - Telas e Insumos')),
  ];

  @override
  Widget build(BuildContext context) {
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
            // Evaluamos si la pantalla es lo suficientemente grande para expandir el menú
            bool isExtended = constraints.maxWidth >= 1000;

            return Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  // === AQUÍ ESTÁ LA CORRECCIÓN ===
                  extended: isExtended,
                  labelType: isExtended
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  // ================================
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
                Expanded(child: _pages[_selectedIndex]),
              ],
            );
          } else {
            // VISTA MOBILE
            return _pages[_selectedIndex];
          }
        },
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width < 800
          ? BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
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
