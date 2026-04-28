class TipoPrendaModel {
  final int id;
  final String nombre;

  TipoPrendaModel({required this.id, required this.nombre});

  factory TipoPrendaModel.fromJson(Map<String, dynamic> json) {
    return TipoPrendaModel(
      id: json['id_tipo_prenda'] as int,
      nombre: json['nombre_prenda'] as String,
    );
  }
}