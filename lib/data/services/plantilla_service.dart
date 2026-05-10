// ============================================================================
// lib/data/services/plantilla_service.dart
// ============================================================================
// MOCK — eliminar / reemplazar con Supabase cuando exista la tabla
// `plantilla_prenda`. La lista vive en memoria del proceso, se pierde al
// reiniciar la app. Mantiene el mismo patrón que `inventario_service.dart`:
// un flag `_useMockData` que conmuta entre lista local y query a Supabase.
//
// - obtenerPlantillas(): devuelve _mockPlantillas (8 plantillas variadas)
// - toggleActiva / nombreYaExiste: helpers para Vista 1
// - crearPlantilla / actualizarPlantilla: usados por el form multi-paso
// - obtenerMedidasSugeridas: lista hardcoded de medidas estándar por tipo,
//   usada en Paso 2 cuando el usuario selecciona tallas y aún no creó
//   manualmente filas de medidas.
// ============================================================================
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/material_plantilla_model.dart';
import '../../domain/models/medida_punto_model.dart';
import '../../domain/models/plantilla_model.dart';

class PlantillaService {
  PlantillaService();

  // Mientras backend no exponga la tabla `plantilla_prenda`, devolvemos mocks.
  static const bool _useMockData = true;

  // MOCK — lista mutable en memoria. Cuando exista backend, eliminar.
  final List<PlantillaModel> _mockPlantillas = [..._mockSeed];

  Future<List<PlantillaModel>> obtenerPlantillas() async {
    try {
      // 👇 Usamos Supabase.instance.client en lugar de solo "supabase"
      final response = await Supabase.instance.client
          .from('plantilla_prenda')
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> data = response;
      return data.map((json) => PlantillaModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Error al cargar plantillas: $e');
    }
  }

  // ─── TOGGLE ACTIVA / INACTIVA ─────────────────────────────────────────────

  /// Conmuta el flag `activa` de la plantilla y devuelve la nueva versión.
  /// En modo mock muta la lista interna; en modo real debe ser un UPDATE.
  Future<PlantillaModel> toggleActiva(String id) async {
    try {
      // 1. Primero leemos la plantilla en la BD para saber su estado actual
      // (OJO: Asegúrate de que el nombre de tu Primary Key sea 'id_plantilla')
      final current = await Supabase.instance.client
          .from('plantilla_prenda')
          .select('activo') // La columna en SQL se llama 'activo'
          .eq('id_plantilla', id)
          .single();

      final bool estadoActual = current['activo'] ?? true;

      // 2. Hacemos el UPDATE mandándole lo contrario (!estadoActual)
      final response = await Supabase.instance.client
          .from('plantilla_prenda')
          .update({'activo': !estadoActual})
          .eq('id_plantilla', id)
          .select() // Pedimos que nos devuelva la fila actualizada
          .single();

      // 3. Devolvemos el modelo actualizado para que Riverpod refresque la pantalla
      return PlantillaModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al cambiar el estado de la plantilla: $e');
    }
  }
  /*(Future<PlantillaModel> toggleActiva(String id) async {
    if (_useMockData) {
      final idx = _mockPlantillas.indexWhere((p) => p.id == id);
      if (idx == -1) {
        throw StateError('Plantilla no encontrada: $id');
      }
      final actual = _mockPlantillas[idx];
      final nueva = actual.copyWith(activa: !actual.activa);
      _mockPlantillas[idx] = nueva;
      return nueva;
    }
    // TODO Backend Mel: UPDATE plantilla SET activa = !activa WHERE id = ?
    throw UnimplementedError('Backend pendiente');
  }*/

  // ─── VALIDACIÓN DE NOMBRE ÚNICO ───────────────────────────────────────────

  /// True si ya existe otra plantilla con ese `nombre` (case-insensitive,
  /// trimmed). `excludeId` permite ignorar la plantilla en edición.
  Future<bool> nombreYaExiste(String nombre, {String? excludeId}) async {
    final target = nombre.toLowerCase().trim();
    if (_useMockData) {
      return _mockPlantillas.any(
        (p) => p.id != excludeId && p.nombre.toLowerCase().trim() == target,
      );
    }
    // TODO Backend Mel: SELECT COUNT(*) FROM plantilla WHERE LOWER(TRIM(nombre)) = LOWER(TRIM(?)) AND id != ?
    throw UnimplementedError('Backend pendiente');
  }

  // ─── CREAR PLANTILLA ──────────────────────────────────────────────────────

  /// Crea una plantilla nueva con version inicial 'v1.0'. El id local es el
  /// timestamp actual; cuando exista backend, será generado por Postgres
  /// (sequence o uuid).
  Future<PlantillaModel> crearPlantilla({
    required String nombre,
    required TipoPrenda tipoPrenda,
    required String especificaciones,
    required List<TallaPrenda> tallasSeleccionadas,
    required List<MedidaPunto> medidas,
    required List<MaterialPlantilla> materiales,
  }) async {
    final nueva = PlantillaModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: nombre,
      tipoPrenda: tipoPrenda,
      version: 'v1.0',
      activa: true,
      createdAt: DateTime.now(),
      especificaciones: especificaciones,
      tallasSeleccionadas: tallasSeleccionadas,
      medidas: medidas,
      materiales: materiales,
    );
    if (_useMockData) {
      _mockPlantillas.add(nueva);
      return nueva;
    }
    // TODO Backend Mel: INSERT INTO plantilla_prenda (...) VALUES (...).
    // Además, esta operación debe insertar las filas hijas en
    // `plantilla_medida` y `plantilla_material` (una fila por cada
    // MedidaPunto y MaterialPlantilla). Sugerido como transaction o RPC
    // para garantizar consistencia entre la plantilla y sus dependencias.
    throw UnimplementedError('Backend pendiente');
  }

  // ─── ACTUALIZAR PLANTILLA ─────────────────────────────────────────────────

  /// Reemplaza la plantilla con `id` por una versión actualizada con los
  /// nuevos datos. La `version` se bumpea automáticamente; `createdAt` se
  /// preserva del original.
  Future<PlantillaModel> actualizarPlantilla({
    required String id,
    required String nombre,
    required TipoPrenda tipoPrenda,
    required String especificaciones,
    required List<TallaPrenda> tallasSeleccionadas,
    required List<MedidaPunto> medidas,
    required List<MaterialPlantilla> materiales,
  }) async {
    if (_useMockData) {
      final idx = _mockPlantillas.indexWhere((p) => p.id == id);
      if (idx == -1) {
        throw StateError('Plantilla no encontrada: $id');
      }
      final original = _mockPlantillas[idx];
      final actualizada = original.copyWith(
        nombre: nombre,
        tipoPrenda: tipoPrenda,
        version: _bumpVersion(original.version),
        especificaciones: especificaciones,
        tallasSeleccionadas: tallasSeleccionadas,
        medidas: medidas,
        materiales: materiales,
      );
      _mockPlantillas[idx] = actualizada;
      return actualizada;
    }
    // TODO Backend Mel: UPDATE plantilla_prenda SET nombre = ?, tipo_prenda = ?,
    // version = ?, especificaciones = ? WHERE id = ?
    // y refrescar las tablas hijas (plantilla_medida, plantilla_material) —
    // sugerido como transaction o RPC para garantizar consistencia. La forma
    // más simple es DELETE + INSERT de las filas hijas dentro de la misma
    // transacción.
    throw UnimplementedError('Backend pendiente');
  }

  // ─── BUMP DE VERSIÓN ──────────────────────────────────────────────────────

  // DECISIÓN: bump del número minor (vX.Y → vX.Y+1).
  // RAZÓN: cambios mantienen compatibilidad mientras la prenda no cambia.
  // CAMBIAR: para cambios mayores (cambio de tipo prenda, reestructuración),
  // bumpear el major (vX → vX+1.0). Por ahora todos los cambios son minor.
  // CAMBIAR: el backend debería generar la versión, no el cliente, para
  // evitar conflicts en escenarios concurrentes.
  String _bumpVersion(String actual) {
    final match = RegExp(r'^v(\d+)\.(\d+)$').firstMatch(actual);
    if (match == null) return 'v1.0';
    final major = int.parse(match.group(1)!);
    final minor = int.parse(match.group(2)!);
    return 'v$major.${minor + 1}';
  }

  // ─── MEDIDAS SUGERIDAS POR TIPO DE PRENDA ─────────────────────────────────

  // DECISIÓN: sugerencias de medidas hardcodeadas por tipo de prenda.
  // RAZÓN: simplifica la UX — al seleccionar tallas, ya hay una tabla
  // sugerida en lugar de partir de cero.
  // CAMBIAR: cuando exista catálogo de medidas estándar en backend
  // (tabla `medida_estandar` con FK a tipo_prenda), reemplazar este mock
  // por una query.
  // TODO Backend Mel: SELECT nombre FROM medida_estandar WHERE tipo_prenda = ?
  Future<List<MedidaPunto>> obtenerMedidasSugeridas(TipoPrenda tipo) async {
    final nombres = _sugerenciasPorTipo[tipo] ?? const ['Medida 1', 'Medida 2'];
    final baseId = DateTime.now().millisecondsSinceEpoch;
    return [
      for (var i = 0; i < nombres.length; i++)
        MedidaPunto(
          id: '${baseId + i}',
          nombre: nombres[i],
          valoresPorTalla: const {},
        ),
    ];
  }
}

// ─── SUGERENCIAS POR TIPO ─ tabla mock que va a desaparecer cuando exista ──
// la tabla `medida_estandar` en el backend.
const Map<TipoPrenda, List<String>> _sugerenciasPorTipo = {
  TipoPrenda.camisas: [
    'Ancho de pecho',
    'Largo total',
    'Largo manga',
    'Ancho hombro',
  ],
  TipoPrenda.pantalones: [
    'Cintura',
    'Cadera',
    'Largo entrepierna',
    'Ancho rodilla',
    'Ruedo',
  ],
  TipoPrenda.polleras: ['Cintura', 'Cadera', 'Largo total'],
  TipoPrenda.vestidos: ['Pecho', 'Cintura', 'Cadera', 'Largo total'],
  TipoPrenda.chombas: ['Ancho de pecho', 'Largo total', 'Largo manga'],
  TipoPrenda.otros: ['Medida 1', 'Medida 2'],
};

// ─── MOCK SEED ──────────────────────────────────────────────────────────────
// Fechas fijas en 2025 para que el listado se vea estable en demos. No usar
// DateTime.now() acá porque rompería un eventual `const`.
//
// Las plantillas '1' y '3' tienen el set completo de datos del form
// (especificaciones / tallas / medidas / materiales) — sirven para probar
// el modo "editar". Las otras 6 quedan con campos default vacíos para
// probar que el form maneja bien plantillas con datos parciales.
//
// Las referencias a `idInsumo` apuntan al seed del módulo Inventario
// (cuando exista en este branch). Hoy son IDs string '1', '4', '9', '10', '3'
// que matchean la convención del PDF.

final List<PlantillaModel> _mockSeed = [
  PlantillaModel(
    id: '1',
    nombre: 'Camisa Manga Larga Clásica',
    tipoPrenda: TipoPrenda.camisas,
    version: 'v2.1',
    activa: true,
    createdAt: DateTime(2025, 3, 12),
    especificaciones:
        'Camisa de vestir manga larga. Cuello clásico, puño doble. '
        'Confección estándar para uso formal o semiformal.',
    tallasSeleccionadas: [
      TallaPrenda.s,
      TallaPrenda.m,
      TallaPrenda.l,
      TallaPrenda.xl,
      TallaPrenda.xxl,
    ],
    medidas: [
      MedidaPunto(
        id: 'med-1-1',
        nombre: 'Ancho de pecho',
        valoresPorTalla: {
          TallaPrenda.s: 50,
          TallaPrenda.m: 52,
          TallaPrenda.l: 54,
          TallaPrenda.xl: 56,
          TallaPrenda.xxl: 58,
        },
      ),
      MedidaPunto(
        id: 'med-1-2',
        nombre: 'Largo total',
        valoresPorTalla: {
          TallaPrenda.s: 70,
          TallaPrenda.m: 72,
          TallaPrenda.l: 74,
          TallaPrenda.xl: 76,
          TallaPrenda.xxl: 78,
        },
      ),
      MedidaPunto(
        id: 'med-1-3',
        nombre: 'Largo manga',
        valoresPorTalla: {
          TallaPrenda.s: 60,
          TallaPrenda.m: 62,
          TallaPrenda.l: 64,
          TallaPrenda.xl: 66,
          TallaPrenda.xxl: 68,
        },
      ),
      MedidaPunto(
        id: 'med-1-4',
        nombre: 'Ancho hombro',
        valoresPorTalla: {
          TallaPrenda.s: 42,
          TallaPrenda.m: 44,
          TallaPrenda.l: 46,
          TallaPrenda.xl: 48,
          TallaPrenda.xxl: 50,
        },
      ),
    ],
    materiales: [
      MaterialPlantilla(id: 'mat-1-1', idInsumo: '1', cantidad: 1.5),
      MaterialPlantilla(id: 'mat-1-2', idInsumo: '9', cantidad: 0.1),
      MaterialPlantilla(id: 'mat-1-3', idInsumo: '4', cantidad: 8),
    ],
  ),
  PlantillaModel(
    id: '2',
    nombre: 'Camisa Manga Corta Sport',
    tipoPrenda: TipoPrenda.camisas,
    version: 'v1.0',
    activa: true,
    createdAt: DateTime(2025, 5, 4),
  ),
  PlantillaModel(
    id: '3',
    nombre: 'Pantalón Cargo Trabajo',
    tipoPrenda: TipoPrenda.pantalones,
    version: 'v3.0',
    activa: true,
    createdAt: DateTime(2024, 11, 22),
    especificaciones:
        'Pantalón cargo de trabajo. Bolsillos laterales con tapa. '
        'Tela resistente.',
    tallasSeleccionadas: [TallaPrenda.m, TallaPrenda.l, TallaPrenda.xl],
    medidas: [
      MedidaPunto(
        id: 'med-3-1',
        nombre: 'Cintura',
        valoresPorTalla: {
          TallaPrenda.m: 40,
          TallaPrenda.l: 44,
          TallaPrenda.xl: 48,
        },
      ),
      MedidaPunto(
        id: 'med-3-2',
        nombre: 'Largo entrepierna',
        valoresPorTalla: {
          TallaPrenda.m: 80,
          TallaPrenda.l: 82,
          TallaPrenda.xl: 84,
        },
      ),
      MedidaPunto(
        id: 'med-3-3',
        nombre: 'Ruedo',
        valoresPorTalla: {
          TallaPrenda.m: 22,
          TallaPrenda.l: 23,
          TallaPrenda.xl: 24,
        },
      ),
    ],
    materiales: [
      MaterialPlantilla(id: 'mat-3-1', idInsumo: '10', cantidad: 2.0),
      MaterialPlantilla(id: 'mat-3-2', idInsumo: '3', cantidad: 0.15),
    ],
  ),
  PlantillaModel(
    id: '4',
    nombre: 'Pantalón Sastre Formal',
    tipoPrenda: TipoPrenda.pantalones,
    version: 'v1.5',
    activa: true,
    createdAt: DateTime(2025, 1, 30),
  ),
  PlantillaModel(
    id: '5',
    nombre: 'Pollera Plisada Escolar',
    tipoPrenda: TipoPrenda.polleras,
    version: 'v2.0',
    activa: true,
    createdAt: DateTime(2025, 2, 18),
  ),
  PlantillaModel(
    id: '6',
    nombre: 'Vestido Casual Verano',
    tipoPrenda: TipoPrenda.vestidos,
    version: 'v1.0',
    activa: false,
    createdAt: DateTime(2024, 9, 8),
  ),
  PlantillaModel(
    id: '7',
    nombre: 'Chomba Polo Empresa',
    tipoPrenda: TipoPrenda.chombas,
    version: 'v4.2',
    activa: true,
    createdAt: DateTime(2025, 4, 1),
  ),
  PlantillaModel(
    id: '8',
    nombre: 'Buzo Capucha Genérico',
    tipoPrenda: TipoPrenda.otros,
    version: 'v1.0',
    activa: false,
    createdAt: DateTime(2024, 7, 14),
  ),
];
