// lib/domain/models/conjunto_model.dart
import 'conjunto_plantilla_model.dart';

class ConjuntoModel {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final bool activo;
  final DateTime fechaCreacion;
  final List<ConjuntoPlantillaModel> plantillas; // Relación con sus piezas

  ConjuntoModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    this.activo = true,
    required this.fechaCreacion,
    this.plantillas = const [],
  });

  // Cálculo dinámico del total basado en las plantillas (opcional si el precio es fijo)
  double get precioCalculado => plantillas.fold(0, (sum, item) => sum + (item.precioUnitario * item.cantidad));

  factory ConjuntoModel.fromJson(Map<String, dynamic> json) {
    return ConjuntoModel(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      precio: (json['precio'] ?? 0).toDouble(),
      activo: json['activo'] ?? true,
      fechaCreacion: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      plantillas: (json['conjunto_plantilla'] as List?)
              ?.map((x) => ConjuntoPlantillaModel.fromJson(x))
              .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'descripcion': descripcion,
      'precio': precio,
      'activo': activo,
    };
  }
}