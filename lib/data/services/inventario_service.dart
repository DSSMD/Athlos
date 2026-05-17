// lib/data/services/inventario_service.dart

import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/inventario_model.dart';

class InventarioService {
  InventarioService();

  // Mientras backend no exponga la tabla `insumos`, devolvemos mocks.
  //static const bool _useMockData = true;

  // MOCK — lista mutable en memoria. Cuando exista backend, eliminar.
  //inal List<InventarioItemModel> _mockItems = [..._mockSeed];

  SupabaseClient get _client => Supabase.instance.client;

  Future<List<InventarioItemModel>> obtenerInventario() async {
    try {
      // Hacemos la consulta real a la tabla 'insumo' y ordenamos alfabéticamente
      final data = await _client
          .from(
            'insumo',
          ) // Asegúrate de que este sea el nombre exacto de tu tabla
          .select('''
          *, 
          unidad_medida(nom_unidad), 
          categoria_insumo(nombre_categoria)
        ''')
          .order('nombre', ascending: true);

      return (data as List).map((e) {
        final json = e as Map<String, dynamic>;

        // 1. Extraemos el texto de la base de datos (ej. "Telas")
        final catData = json['categoria_insumo'];
        String nombreCat = 'telas'; // valor por defecto seguro
        if (catData != null && catData is Map) {
          nombreCat = catData['nombre_categoria']?.toString() ?? 'telas';
        }

        return InventarioItemModel.fromJson(json);
      }).toList();
    } catch (e) {
      print('🚨 ERROR SUPABASE LECTURA: $e');
      throw Exception('Error al obtener el inventario: $e');
    }
  }

  Future<List<Map<String, dynamic>>> obtenerCategoriasDropdown() async {
    try {
      final data = await _client
          .from('categoria_insumo') // Reemplaza si tu tabla tiene otro nombre
          .select('id_categoria, nombre_categoria')
          .order('id_categoria', ascending: true);

      // Devolvemos una lista cruda para que el Dropdown la lea fácilmente
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('🚨 ERROR AL CARGAR CATEGORÍAS DROPDOWN: $e');
      throw Exception('Error al cargar opciones de categorías');
    }
  }

  Future<List<Map<String, dynamic>>> obtenerUnidadesDropdown() async {
    try {
      final data = await _client
          .from('unidad_medida')
          .select('id_unidad, nom_unidad')
          .order('id_unidad', ascending: true);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('🚨 ERROR AL CARGAR UNIDADES DROPDOWN: $e');
      throw Exception('Error al cargar opciones de unidades');
    }
  }

  /// Devuelve solo las unidades de medida válidas para [idCategoria],
  /// consultando la tabla intermedia `categoria_unidad` con JOIN a `unidad_medida`.
  Future<List<Map<String, dynamic>>> obtenerUnidadesPorCategoria(
    int idCategoria,
  ) async {
    try {
      final data = await _client
          .from('categoria_unidad')
          .select('unidad_medida(id_unidad, nom_unidad)')
          .eq('id_categoria', idCategoria)
          .order('id_unidad', referencedTable: 'unidad_medida', ascending: true);

      // Supabase devuelve [{unidad_medida: {id_unidad: x, nom_unidad: y}}, ...]
      // Lo aplanamos al mismo formato que los demás dropdowns.
      return (data as List).map<Map<String, dynamic>>((row) {
        final u = row['unidad_medida'] as Map<String, dynamic>;
        return {
          'id_unidad': u['id_unidad'] as int,
          'nom_unidad': u['nom_unidad'].toString(),
        };
      }).toList();
    } catch (e) {
      throw Exception('Error al cargar unidades para la categoría: $e');
    }
  }

  Future<void> actualizarEstadoActivo(String idInsumo, bool nuevoEstado) async {
    try {
      await _client
          .from('insumo')
          .update({
            'activo': nuevoEstado,
          }) // 👈 Actualizamos solo la columna activo
          .eq('id_insumo', idInsumo); // 👈 Filtramos por el ID del insumo
    } catch (e) {
      throw Exception('Error al cambiar estado del insumo: $e');
    }
  }

  Future<InventarioItemModel> crearInsumo({
    required String nombre,
    required int idCategoria,
    required double stockMinimo,
    required int idUnidad,
    required bool dimensionable,
    String? atributosTecnicosJson,
  }) async {
    try {
      final payload = <String, dynamic>{
        'nombre': nombre,
        'id_categoria': idCategoria,
        'stock_actual': 0,   // inicia en 0; el trigger lo actualiza en el primer ingreso
        'stock_minimo': stockMinimo,
        'id_unidad': idUnidad,
        'activo': true,      // 👈 Fuerza que sea activo para que aparezca en catálogos
        // costo_unitario omitido: el trigger de Costo Promedio Ponderado lo calcula
        // automáticamente al insertar el primer movimiento_insumo de entrada.
        if (atributosTecnicosJson != null && atributosTecnicosJson.isNotEmpty)
          'atributos_tecnicos': jsonDecode(atributosTecnicosJson),
      };

      final response = await _client
          .from('insumo')
          .insert(payload)
          .select(
            '*, unidad_medida(nom_unidad), categoria_insumo(nombre_categoria)',
          )
          .single();

      return InventarioItemModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear el insumo en Supabase: $e');
    }
  }

  /// Actualiza directamente `stock_actual` en la tabla `insumo`.
  /// Usado por [InventarioNotifier.actualizarStock] tras registrar un movimiento.
  Future<void> actualizarStockInsumo(
    String idInsumo,
    double nuevoStock,
  ) async {
    try {
      await _client
          .from('insumo')
          .update({'stock_actual': nuevoStock})
          .eq('id_insumo', idInsumo);
    } catch (e) {
      throw Exception('Error al actualizar stock del insumo: $e');
    }
  }
}


