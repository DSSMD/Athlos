import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/legacy.dart';

// Este es el provider que observarás desde tu MaterialApp
final isConnectedProvider = StateNotifierProvider<ConnectivityNotifier, bool>((ref) {
  return ConnectivityNotifier();
});

class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier() : super(true) {
    _initWatcher();
  }

  void _initWatcher() {
    // Escuchamos los cambios en la red (Wifi/Datos) en tiempo real
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      // Si la lista de resultados contiene 'none', perdimos la conexión
      if (results.contains(ConnectivityResult.none)) {
        state = false;
      } else {
        state = true;
      }
    });
  }

  // Esta función es para el botón "Reintentar" de tu NoInternetOverlay
  Future<void> checkConnectionManual() async {
    final results = await Connectivity().checkConnectivity();
    state = !results.contains(ConnectivityResult.none);
  }
}