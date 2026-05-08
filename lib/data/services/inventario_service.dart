// lib/data/services/inventario_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/inventario_item_model.dart';

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

        // 2. Lo convertimos al Enum que el Frontend necesita
        final catEnum = CategoriaInsumo.values.firstWhere(
          (enumItem) => enumItem.name.toLowerCase() == nombreCat.toLowerCase(),
          orElse: () => CategoriaInsumo.telas,
        );

        // 3. Modificamos el JSON temporalmente para que tu fromJson lo lea perfecto
        json['categoria_enum'] = catEnum;

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
          .from('unidad_medida') // Reemplaza si tu tabla tiene otro nombre
          .select('id_unidad, nom_unidad')
          .order('id_unidad', ascending: true);

      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('🚨 ERROR AL CARGAR UNIDADES DROPDOWN: $e');
      throw Exception('Error al cargar opciones de unidades');
    }
  }

  Future<InventarioItemModel> crearInsumo({
    required String codigo,
    required String nombre,
    required int idCategoria,
    required double stockMinimo,
    required int idUnidad,
    required double costoUnitario,
    required bool dimensionable,
    String? atributosTecnicosJson,
  }) async {
    try {
      // Armamos el payload (JSON) que vamos a enviar a la base de datos
      final payload = {
        'nombre': nombre,
        // Convertimos el enum a String para guardarlo en BD (ej: "telas")
        'id_categoria': idCategoria,
        'stock_actual': 0, // Como pidió Den, siempre inicia en 0
        'stock_minimo': stockMinimo,
        'id_unidad': idUnidad,
        'costo_unitario': costoUnitario,
        if (atributosTecnicosJson != null)
          'atributos_tecnicos': atributosTecnicosJson,
      };

      // Insertamos y le pedimos a Supabase que nos devuelva la fila recién creada (.select().single())
      final response = await _client
          .from('insumo')
          .insert(payload)
          .select(
            '*, unidad_medida(nom_unidad), categoria_insumo(nombre_categoria)',
          )
          .single();

      // Devolvemos el modelo creado para que la UI se actualice al instante
      return InventarioItemModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al crear el insumo en Supabase: $e');
    }

    // MOCK — eliminar / reemplazar con Supabase cuando exista insert.
    // Stock inicia en 0 (anotación de Den en el PDF).
    /*final nuevo = InventarioItemModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      codigo: codigo,
      nombre: nombre,
      categoria: categoria,
      stockActual: 0,
      stockMinimo: stockMinimo,
      unidad: unidad,
      costoUnitario: costoUnitario,
      dimensionable: dimensionable,
      atributosTecnicosJson: atributosTecnicosJson,
    );

    if (_useMockData) {
      _mockItems.add(nuevo);
    } else {
      // TODO: insertar en Supabase tabla `insumos`.
      throw UnimplementedError('Backend pendiente');
    }

    return nuevo;*/
  }
}

// ─── MOCK DATA ────────────────────────────────────────────────────────────────
/*
const List<InventarioItemModel> _mockSeed = [
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
];*/
