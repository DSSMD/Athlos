// lib/domain/models/inventario_item_model.dart

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
  });

  final String id;
  final String codigo;
  final String nombre;
  final CategoriaInsumo categoria;
  final double stockActual;
  final double stockMinimo;
  final String unidad;
  final double costoUnitario;

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
    return InventarioItemModel(
      id: json['id'].toString(),
      codigo: (json['codigo'] ?? '') as String,
      nombre: (json['nombre'] ?? '') as String,
      categoria: CategoriaInsumo.fromString(json['categoria'] as String?),
      stockActual: (json['stock_actual'] as num?)?.toDouble() ?? 0,
      stockMinimo: (json['stock_minimo'] as num?)?.toDouble() ?? 0,
      unidad: (json['unidad'] ?? 'unidades') as String,
      costoUnitario: (json['costo_unitario'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'nombre': nombre,
      'categoria': categoria.name,
      'stock_actual': stockActual,
      'stock_minimo': stockMinimo,
      'unidad': unidad,
      'costo_unitario': costoUnitario,
    };
  }
}
