// lib/domain/models/inventario_item_model.dart
import 'dart:convert';

enum StockState { ok, alerta, bajo, critico }

enum CategoriaInsumo {
  telas,
  hilos,
  accesorios,
  etiquetas,
  empaque,
  otros;

  String get label {
    switch (this) {
      case CategoriaInsumo.telas:
        return 'Telas';
      case CategoriaInsumo.hilos:
        return 'Hilos';
      case CategoriaInsumo.accesorios:
        return 'Accesorios';
      case CategoriaInsumo.etiquetas:
        return 'Etiquetas';
      case CategoriaInsumo.empaque:
        return 'Empaque';
      case CategoriaInsumo.otros:
        return 'Otros';
    }
  }

  static CategoriaInsumo fromString(String? raw) {
    switch (raw) {
      case 'telas':
        return CategoriaInsumo.telas;
      case 'hilos':
        return CategoriaInsumo.hilos;
      case 'accesorios':
        return CategoriaInsumo.accesorios;
      case 'etiquetas':
        return CategoriaInsumo.etiquetas;
      case 'empaque':
        return CategoriaInsumo.empaque;
      default:
        return CategoriaInsumo.otros;
    }
  }
}

class InventarioItemModel {
  const InventarioItemModel({
    required this.id,
    required this.codigo,
    required this.nombre,
    required this.categoria,
    required this.stockActual,
    required this.stockMinimo,
    required this.unidad,
    required this.costoUnitario,
    required this.activo,
    this.dimensionable = false,
    this.atributosTecnicosJson,
  });

  final String id;
  final String codigo;
  final String nombre;
  final CategoriaInsumo categoria;
  final double stockActual;
  final double stockMinimo;
  final String unidad;
  final double costoUnitario;
  final bool dimensionable;
  final String? atributosTecnicosJson;
  final bool activo;

  double get valorTotal => stockActual * costoUnitario;

  double get nivelPorcentaje =>
      stockMinimo == 0 ? 100.0 : (stockActual / stockMinimo) * 100;

  StockState get estado {
    final n = nivelPorcentaje;
    if (n < 25) return StockState.critico;
    if (n < 50) return StockState.bajo;
    if (n < 100) return StockState.alerta;
    return StockState.ok;
  }

  factory InventarioItemModel.fromJson(Map<String, dynamic> json) {
    // Extraemos el nombre de la unidad del objeto anidado
    // Supabase devuelve la relación como un objeto o una lista
    final unidadData = json['unidad_medida'];
    String nombreUnidad = 'N/A';

    // 2. Extraemos el texto "nom_unidad"
    if (unidadData != null) {
      if (unidadData is Map) {
        nombreUnidad = unidadData['nom_unidad']?.toString() ?? 'N/A';
      } else if (unidadData is List && unidadData.isNotEmpty) {
        nombreUnidad = unidadData[0]['nom_unidad']?.toString() ?? 'N/A';
      }
    }

    final catData = json['categoria_insumo'];
    String nombreCategoria = 'Sin categoría';

    if (catData != null) {
      if (catData is Map) {
        nombreCategoria =
            catData['nombre_categoria']?.toString() ?? 'Sin categoría';
      } else if (catData is List && catData.isNotEmpty) {
        nombreCategoria =
            catData[0]['nombre_categoria']?.toString() ?? 'Sin categoría';
      }
    }
    return InventarioItemModel(
      id: json['id_insumo'] ?? '',
      codigo: json['id_insumo'].toString().substring(0, 8).toUpperCase(),
      nombre: (json['nombre'] ?? '') as String,
      categoria: CategoriaInsumo.fromString(nombreCategoria),
      stockActual: json['stock_actual'] != null
          ? double.tryParse(json['stock_actual'].toString()) ?? 0.0
          : 0.0,
      stockMinimo: json['stock_minimo'] != null
          ? double.tryParse(json['stock_minimo'].toString()) ?? 0.0
          : 0.0,
      unidad: nombreUnidad,
      costoUnitario: json['costo_unitario'] != null
          ? double.tryParse(json['costo_unitario'].toString()) ?? 0.0
          : 0.0,
      dimensionable: (json['dimensionable'] as bool?) ?? false,
      atributosTecnicosJson: json['atributos_tecnicos'] != null
          ? jsonEncode(json['atributos_tecnicos'])
          : null,
      activo: (json['activo'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_insumo': codigo,
      'nombre': nombre,
      'categoria': categoria.name,
      'stock_actual': stockActual,
      'stock_minimo': stockMinimo,
      'unidad': unidad,
      'costo_unitario': costoUnitario,
      'dimensionable': dimensionable,
      if (atributosTecnicosJson != null)
        'atributos_tecnicos_json': atributosTecnicosJson,
    };
  }
}
