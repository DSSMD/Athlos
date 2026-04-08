import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

// ==========================================
// 1. CLASE DE ESTADO (Los datos del formulario)
// ==========================================
class OrdenFormState {
  final String nombreModelo;
  final String? imagePath;
  final Map<String, int> tallas;

  OrdenFormState({
    this.nombreModelo = '',
    this.imagePath,
    this.tallas = const {'S': 0, 'M': 0, 'L': 0, 'XL': 0},
  });

  // CA 3: Cálculo automático del total de prendas
  int get totalPrendas => tallas.values.fold(0, (sum, cantidad) => sum + cantidad);

  // CA 4: Validación de campos obligatorios
  bool get esValido {
    final tieneNombre = nombreModelo.trim().isNotEmpty;
    final tieneImagen = imagePath != null;
    final tieneCantidades = totalPrendas > 0;
    
    return tieneNombre && tieneImagen && tieneCantidades;
  }

  OrdenFormState copyWith({
    String? nombreModelo,
    String? imagePath,
    Map<String, int>? tallas,
  }) {
    return OrdenFormState(
      nombreModelo: nombreModelo ?? this.nombreModelo,
      imagePath: imagePath ?? this.imagePath,
      tallas: tallas ?? this.tallas,
    );
  }
}

// ==========================================
// 2. CONTROLADOR (La lógica de negocio de la UI)
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

  Future<void> guardarOrden() async {
    if (!state.esValido) return;

    // Adaptación a la tabla `detalle_orden` de Athlos
    List<Map<String, dynamic>> detallesParaBD = [];
    
    state.tallas.forEach((talla, cantidad) {
      if (cantidad > 0) {
        detallesParaBD.add({
          'producto': '${state.nombreModelo} - Talla $talla',
          'cantidad': cantidad,
        });
      }
    });

    // Aquí iría la llamada real al repositorio
    // Aquí iría la llamada real al repositorio
    debugPrint('✅ GUARDANDO ORDEN...');
    debugPrint('Ruta Imagen: ${state.imagePath}');
    debugPrint('Detalles procesados: $detallesParaBD');
    
    // Limpiamos el formulario tras guardar exitosamente
    state = OrdenFormState(); 
  }
}

// ==========================================
// 3. PROVIDER (Para inyectarlo en la vista)
// ==========================================
final ordenFormProvider = NotifierProvider<OrdenFormNotifier, OrdenFormState>(() {
  return OrdenFormNotifier();
});