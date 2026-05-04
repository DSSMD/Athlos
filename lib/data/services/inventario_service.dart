// lib/data/services/inventario_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/inventario_item_model.dart';

class InventarioService {
  InventarioService();

  // Mientras backend no exponga la tabla `insumos`, devolvemos mocks.
  static const bool _useMockData = true;

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<InventarioItemModel>> obtenerInventario() async {
    if (_useMockData) {
      return _mockInventario;
    }

    // TODO: cuando backend exponga la tabla, ajustar columnas/relaciones.
    final data = await _client.from('insumos').select();
    return (data as List)
        .map((e) => InventarioItemModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

// ─── MOCK DATA ────────────────────────────────────────────────────────────────

const List<InventarioItemModel> _mockInventario = [
  InventarioItemModel(
    id: '3',
    codigo: 'INS-003',
    nombre: 'Hilo negro #120',
    categoria: CategoriaInsumo.hilos,
    stockActual: 12,
    stockMinimo: 50,
    unidad: 'conos',
    costoUnitario: 18.5,
  ),
  InventarioItemModel(
    id: '6',
    codigo: 'INS-006',
    nombre: 'Elástico 3cm',
    categoria: CategoriaInsumo.accesorios,
    stockActual: 25,
    stockMinimo: 50,
    unidad: 'metros',
    costoUnitario: 4.2,
  ),
  InventarioItemModel(
    id: '2',
    codigo: 'INS-002',
    nombre: 'Tela poliéster azul',
    categoria: CategoriaInsumo.telas,
    stockActual: 45,
    stockMinimo: 100,
    unidad: 'metros',
    costoUnitario: 32.0,
  ),
  InventarioItemModel(
    id: '9',
    codigo: 'INS-009',
    nombre: 'Hilo blanco #100',
    categoria: CategoriaInsumo.hilos,
    stockActual: 58,
    stockMinimo: 50,
    unidad: 'conos',
    costoUnitario: 17.0,
  ),
  InventarioItemModel(
    id: '1',
    codigo: 'INS-001',
    nombre: 'Tela algodón blanco',
    categoria: CategoriaInsumo.telas,
    stockActual: 380,
    stockMinimo: 100,
    unidad: 'metros',
    costoUnitario: 28.5,
  ),
  InventarioItemModel(
    id: '4',
    codigo: 'INS-004',
    nombre: 'Botones plástico 4H',
    categoria: CategoriaInsumo.accesorios,
    stockActual: 4000,
    stockMinimo: 1000,
    unidad: 'unidades',
    costoUnitario: 0.35,
  ),
  InventarioItemModel(
    id: '5',
    codigo: 'INS-005',
    nombre: 'Cierres metálicos 20cm',
    categoria: CategoriaInsumo.accesorios,
    stockActual: 890,
    stockMinimo: 200,
    unidad: 'unidades',
    costoUnitario: 5.8,
  ),
  InventarioItemModel(
    id: '10',
    codigo: 'INS-010',
    nombre: 'Tela drill caqui',
    categoria: CategoriaInsumo.telas,
    stockActual: 200,
    stockMinimo: 100,
    unidad: 'metros',
    costoUnitario: 42.0,
  ),
];
