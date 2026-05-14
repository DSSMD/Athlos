class LoteModel {
  final String id;
  final String ordenId;
  final String cliente;
  final String prenda;
  final List<String> tallas;
  final int cantidad;
  final String areaActual;
  final String idArea;
  final String estado;

  LoteModel({
    required this.id,
    required this.ordenId,
    required this.cliente,
    required this.prenda,
    required this.tallas,
    required this.cantidad,
    required this.areaActual,
    required this.idArea,
    required this.estado,
  });

  factory LoteModel.fromJson(Map<String, dynamic> json) {
    print('--- DATOS DEL LOTE ${json['id_lote']} ---');
    print('Estado JSON: ${json['estado_lote']}');
    // Supabase devuelve los JOINs como diccionarios anidados

    final orden = json['orden'] ?? {};
    final clienteMap = orden['cliente'] ?? {};
    final plantilla = json['plantilla_prenda'] ?? {};
    final area = json['areas'] ?? {};
    final idEstado = json['id_estado_lote']?.toString();
    // Mapeo seguro de tallas (en caso de que venga anidado o vacío)
    // Esto dependerá de cómo hagamos el join de las tallas en el service
    List<String> tallasList = [];
    if (json['tallas'] != null && json['tallas'] is List) {
      tallasList = List<String>.from(json['tallas'].map((x) => x.toString()));
    }
    String traducirEstado(String? id) {
      switch (id) {
        case '1':
          return 'Pendiente';
        case '2':
          return 'En Corte';
        case '3':
          return 'Listo para Sublimado';
        case '4':
          return 'En Sublimado';
        case '5':
          return 'Listo para Confección';
        case '6':
          return 'En Confección';
        case '7':
          return 'Terminado';
        default:
          return 'Desconocido ($id)';
      }
    }

    return LoteModel(
      id: json['id_lote']?.toString() ?? 'ID_NO_ENCONTRADO',
      ordenId: orden['num_orden']?.toString() ?? 'Sin Orden',
      cliente: clienteMap['nom_cliente']?.toString() ?? 'Cliente N/A',
      // Cambia 'nombre_plantilla' por la clave que hayas puesto en el service
      prenda: plantilla['nombre']?.toString() ?? 'Prenda N/A',
      tallas: tallasList.isEmpty ? ['N/A'] : tallasList,
      cantidad: (json['cantidad_asignada'] as num?)?.toInt() ?? 0,
      areaActual: area['nombre_area']?.toString() ?? 'Sin área',
      estado: traducirEstado(idEstado),
      idArea: json['id_area_actual']?.toString() ?? '',
    );
  }
}
