// lib/core/router/router_notifier.dart
// Este archivo define un RouterNotifier que se integra con Riverpod para escuchar cambios en el estado de autenticación y perfil del usuario.
// La idea es que cada vez que el estado de autenticación o el perfil del usuario cambie, le notificamos a GoRouter para que recalcule las rutas y muestre la pantalla correcta.
// Asegúrate de ajustar las rutas de importación según la estructura de tu proyecto y los nombres de tus providers.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Ajusta esta ruta a donde tengas tu auth_provider.dart
import '../../presentation/providers/auth_provider.dart';

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  ref.keepAlive();
  return RouterNotifier(ref);
});

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    // 1. Escuchamos cambios en la sesión (Login/Logout)
    _ref.listen(authStateProvider, (_, _) => notifyListeners());

    // 2. Escuchamos cambios en tu perfil completo (Nombre y Rol)
    _ref.listen(userProfileProvider, (_, _) => notifyListeners());
  }
}
