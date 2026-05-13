class LoteModel {
  final String id;
  final String ordenId;
  final String cliente;
  final String prenda;
  final List<String> tallas;
  final int cantidad;
  final String areaActual;
  final String estado;

  LoteModel({
    required this.id,
    required this.ordenId,
    required this.cliente,
    required this.prenda,
    required this.tallas,
    required this.cantidad,
    required this.areaActual,
    required this.estado,
  });
}