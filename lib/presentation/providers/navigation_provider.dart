import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationNotifier extends Notifier<int> {
  // El método build define el estado inicial (0 = Dashboard)
  @override
  int build() {
    return 0;
  }

  // Método opcional pero recomendado para cambiar el valor
  void changeIndex(int newIndex) {
    state = newIndex;
  }
}

final navigationIndexProvider = NotifierProvider<NavigationNotifier, int>(() {
  return NavigationNotifier();
});
