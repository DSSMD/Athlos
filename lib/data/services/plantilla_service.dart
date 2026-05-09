// ============================================================================
// lib/data/services/plantilla_service.dart
// ============================================================================
// MOCK — eliminar / reemplazar con Supabase cuando exista la tabla
// `plantilla_prenda`. La lista vive en memoria del proceso, se pierde al
// reiniciar la app. Mantiene el mismo patrón que `inventario_service.dart`:
// un flag `_useMockData` que conmuta entre lista local y query a Supabase.
//
// - obtenerPlantillas(): devuelve _mockPlantillas (8 plantillas variadas)
// - _mockPlantillas: seed mutable para que la UI pueda agregarlas en el
//   futuro sin reescribir el seed
// ============================================================================

import '../../domain/models/plantilla_model.dart';

class PlantillaService {
  PlantillaService();

  // Mientras backend no exponga la tabla `plantilla_prenda`, devolvemos mocks.
  static const bool _useMockData = true;

  // MOCK — lista mutable en memoria. Cuando exista backend, eliminar.
  final List<PlantillaModel> _mockPlantillas = [..._mockSeed];

  Future<List<PlantillaModel>> obtenerPlantillas() async {
    if (_useMockData) {
      return List.unmodifiable(_mockPlantillas);
    }
    // TODO(plantillas-modulo): query a Supabase tabla `plantilla_prenda` con
    // join a `tipo_prenda`. Ajustar columnas/relaciones cuando backend exista.
    throw UnimplementedError('Backend pendiente');
  }

  // ─── TOGGLE ACTIVA / INACTIVA ─────────────────────────────────────────────

  /// Conmuta el flag `activa` de la plantilla y devuelve la nueva versión.
  /// En modo mock muta la lista interna; en modo real debe ser un UPDATE.
  Future<PlantillaModel> toggleActiva(String id) async {
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
  }

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
}

// ─── MOCK SEED ──────────────────────────────────────────────────────────────
// Fechas fijas en 2025 para que el listado se vea estable en demos. No usar
// DateTime.now() acá porque rompería un eventual `const`.

final List<PlantillaModel> _mockSeed = [
  PlantillaModel(
    id: '1',
    nombre: 'Camisa Manga Larga Clásica',
    tipoPrenda: TipoPrenda.camisas,
    version: 'v2.1',
    activa: true,
    createdAt: DateTime(2025, 3, 12),
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
