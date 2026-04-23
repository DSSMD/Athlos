class TelaModel {
  final String id;
  final String tipo;
  final double metrosDisponibles;
  final String color;

  TelaModel({
    required this.id,
    required this.tipo,
    required this.metrosDisponibles,
    required this.color,
  });

  factory TelaModel.fromJson(Map<String, dynamic> json) {
    return TelaModel(
      id: json['id'] as String,
      tipo: json['tipo'] as String,
      metrosDisponibles: (json['metros_disponibles'] as num).toDouble(),
      color: json['color'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipo': tipo,
      'metros_disponibles': metrosDisponibles,
      'color': color,
    };
  }
}