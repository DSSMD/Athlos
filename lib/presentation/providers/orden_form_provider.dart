// lib/presentation/providers/orden_form_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'orden_provider.dart'; 

// ==========================================
// 1. CLASE DE ESTADO (Se mantiene igual, ¡es perfecta!)
// ==========================================
class OrdenFormState {
  final String nombreModelo;
  final String? imagePath;
  final Map<String, int> tallas;
  final DateTime? fechaEntrega;
  final String? idCliente;

  OrdenFormState({
    this.nombreModelo = '',
    this.imagePath,
    this.tallas = const {'S': 0, 'M': 0, 'L': 0, 'XL': 0},
    this.fechaEntrega,
    this.idCliente,
  });

  int get totalPrendas =>
      tallas.values.fold(0, (sum, cantidad) => sum + cantidad);

  bool get esValido {
    return nombreModelo.trim().isNotEmpty &&
        imagePath != null &&
        totalPrendas > 0 &&
        fechaEntrega != null &&
        (idCliente != null && idCliente!.trim().isNotEmpty);
  }

  OrdenFormState copyWith({
    String? nombreModelo,
    String? imagePath,
    Map<String, int>? tallas,
    DateTime? fechaEntrega,
    String? idCliente,
  }) {
    return OrdenFormState(
      nombreModelo: nombreModelo ?? this.nombreModelo,
      imagePath: imagePath ?? this.imagePath,
      tallas: tallas ?? this.tallas,
      fechaEntrega: fechaEntrega ?? this.fechaEntrega,
      idCliente: idCliente ?? this.idCliente,
    );
  }
}

// ==========================================
// 2. CONTROLADOR (Actualizado con Inyección de Dependencias)
// ==========================================
class OrdenFormNotifier extends Notifier<OrdenFormState> {
  @override
  OrdenFormState build() {
    return OrdenFormState();
  }

  void updateNombreModelo(String nombre) {
    state = state.copyWith(nombreModelo: nombre);
  }

  void updateImagePath(String path) {
    state = state.copyWith(imagePath: path);
  }

  void updateCantidadTalla(String talla, int cantidad) {
    final nuevasTallas = Map<String, int>.from(state.tallas);
    nuevasTallas[talla] = cantidad;
    state = state.copyWith(tallas: nuevasTallas);
  }

  void updateFechaEntrega(DateTime fecha) {
    state = state.copyWith(fechaEntrega: fecha);
  }

  void updateIdCliente(String id) {
    state = state.copyWith(idCliente: id);
  }

  Future<void> guardarOrden() async {
    if (!state.esValido) return;

    try {
      debugPrint('⏳ Iniciando guardado en Supabase...');

      // 1. Obtenemos el servicio a través de Riverpod en lugar de instanciarlo directo
      final servicio = ref.read(ordenServiceProvider);
      
      // 2. Guardamos enviando todo el estado
      await servicio.crearOrdenMultimodal(state);

      debugPrint('✅ Flujo de guardado completado en la BD real.');

      // 3. ¡LA MAGIA DE RIVERPOD! 
      // Le decimos a la lista de órdenes que se vuelva a cargar para que aparezca la nueva
      ref.read(ordenesProvider.notifier).refreshOrdenes();

      // 4. Limpiamos el formulario tras guardar exitosamente
      state = OrdenFormState();
      
    } catch (e) {
      debugPrint('❌ Falló el guardado: $e');
      // Aquí podrías agregar lógica para mostrar un SnackBar de error en la UI
    }
  }
}

// ==========================================
// 3. PROVIDER (Para inyectarlo en la vista)
// ==========================================
final ordenFormProvider = NotifierProvider<OrdenFormNotifier, OrdenFormState>(
  () {
    return OrdenFormNotifier();
  },
);
