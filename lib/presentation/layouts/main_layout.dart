import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';
import '../widgets/athlos_app_bar.dart'; // Importamos el AppBar

class MainLayout extends ConsumerWidget {
  // Parámetros dinámicos según el rol
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

    return Scaffold(
      appBar: const AthlosAppBar(), // Usamos el widget extraído
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 800) {
            bool isExtended = constraints.maxWidth >= 1000;

            return Row(
              children: [
                NavigationRail(
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (int index) {
                    ref.read(navigationIndexProvider.notifier).changeIndex(index);
                  },
                  extended: isExtended,
                  labelType: isExtended
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  destinations: railDestinations, // Usamos la lista inyectada
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: pages[selectedIndex]), // Mostramos la página correspondiente
              ],
            );
          } else {
            return pages[selectedIndex];
          }
        },
      ),
      bottomNavigationBar: MediaQuery.of(context).size.width < 800
          ? BottomNavigationBar(
              currentIndex: selectedIndex,
              onTap: (index) {
                ref.read(navigationIndexProvider.notifier).changeIndex(index);
              },
              items: bottomNavItems, // Usamos la lista inyectada
            )
          : null,
    );
  }
}