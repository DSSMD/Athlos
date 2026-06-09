import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

class NavigationNotifier extends Notifier<int> {
  // El método build define el estado inicial (0 = Dashboard)
  @override
  int build() {
    ref.listen(userProfileProvider, (previous, next) {
      if (previous?.value != next.value) {
        state = 0;
      }
    });
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

