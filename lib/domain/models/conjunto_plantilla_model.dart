// lib/domain/models/conjunto_plantilla_model.dart

class ConjuntoPlantillaModel {
  final String id; // ID de la relación intermedia
  final String conjuntoId;
  final String plantillaId;
  final String nombrePlantilla; // Para mostrar en UI sin buscar otra vez
  final int cantidad;
  final double precioUnitario; // Precio al momento de la consulta

  ConjuntoPlantillaModel({
    required this.id,
    required this.conjuntoId,
    required this.plantillaId,
    required this.nombrePlantilla,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get subtotal => cantidad * precioUnitario;

  factory ConjuntoPlantillaModel.fromJson(Map<String, dynamic> json) {
    return ConjuntoPlantillaModel(
      id: json['id']?.toString() ?? '',
      conjuntoId: json['id_conjunto']?.toString() ?? '',
      plantillaId: json['id_plantilla']?.toString() ?? '',
      // Asumiendo que el backend hace un join con la tabla plantillas
      nombrePlantilla: json['plantillas']?['nombre'] ?? 'Desconocido',
      precioUnitario: (json['plantillas']?['precio_unitario'] ?? 0).toDouble(),
      cantidad: json['cantidad'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_conjunto': conjuntoId,
      'id_plantilla': plantillaId,
      'cantidad': cantidad,
    };
  }
}