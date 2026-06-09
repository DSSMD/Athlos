// ============================================================================
// lib/data/services/plantilla_service.dart
// ============================================================================
// Servicio del módulo Plantillas — integración directa con Supabase.
//
// Tablas que toca:
// - plantilla_prenda (tabla principal)
// - medida_ficha    (medidas asociadas, FK CASCADE)
// - receta_material (materiales asociados, FK CASCADE)
//
// IMPORTANTE: las operaciones de crear/actualizar NO son transaccionales a
// nivel cliente. Si una operación múltiple falla a medias, puede quedar
// data huérfana. Para mejorar:
// plantilla con sus hijas en una sola transacción atómica.
//
// IMPORTANTE: existe trigger en receta_material que bloquea inserts con
// insumos inactivos. El service traduce ese error a un mensaje amigable.
// ============================================================================
// El PDF de Den especifica que en modo editar "se podrá editar pero no todo".
// Decisión arquitectónica pendiente:
//
// 1. ¿Qué campos son INMUTABLES una vez creada la plantilla?
//    - Candidatos: id_tipo_prenda (cambiar el tipo cambia el sentido de
//      las medidas y materiales asociados).
//    - Posibles: tallasSeleccionadas (deselect en versión nueva podría
//      dejar órdenes históricas huérfanas).
//
// 2. ¿Qué campos son EDITABLES en cualquier versión?
//    - Probables: nombre, especificaciones, activo.
//
// 3. Implementación sugerida:
//    a) Validar a nivel BD con un trigger en plantilla_prenda que
//       bloquee UPDATEs de columnas inmutables.
//    b) O bien validar a nivel app en actualizarPlantilla() acá.
//
// Mientras tanto: el front muestra un banner informativo en el Paso 4 al
// crear, pero NO bloquea la edición de ningún campo en modo editar
// (todos pueden cambiarse hoy).
// ============================================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/material_plantilla_model.dart';
import '../../domain/models/medida_punto_model.dart';
import '../../domain/models/plantilla_model.dart';

class PlantillaService {
  final SupabaseClient _client = Supabase.instance.client;

  // ─── OBTENER PLANTILLAS ────────────────────────────────────────────────────

  /// Listado plano (sin medidas ni materiales) — usado por la Vista 1.
  Future<List<PlantillaModel>> obtenerPlantillas() async {
    try {
      final response = await _client
          .from('plantilla_prenda')
          .select()
          .order('created_at', ascending: false);
      return (response as List)
          .map((j) => PlantillaModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Error al cargar plantillas: $e');
    }
  }

  /// Carga plantilla con sus materiales (para abrir el form en
  /// modo editar).
  Future<PlantillaModel> obtenerPlantillaCompleta(String idPlantilla) async {
    try {
      final res = await _client
          .from('plantilla_prenda')
          .select('''
            *,
            receta_material (
              id_receta,
              id_insumo,
              cantidad_requerida
            ),
            medida_ficha (
              id_talla
            )
          ''')
          .eq('id_plantilla', idPlantilla)
          .single();

      final plantillaBase = PlantillaModel.fromJson(res);

      // Parsear materiales
      final rawMateriales = res['receta_material'] as List?;
      final materiales = rawMateriales?.map((r) {
            return MaterialPlantilla.fromJson(r as Map<String, dynamic>);
          }).toList() ??
          [];

      // Parsear tallas seleccionadas
      final rawMedidas = res['medida_ficha'] as List?;
      final tallas = rawMedidas?.map((r) {
            final val = r['id_talla'];
            return val is int ? val : int.tryParse(val?.toString() ?? '');
          }).whereType<int>().toSet().toList() ??
          [];

      return plantillaBase.copyWith(
        tallasSeleccionadas: tallas,
        materiales: materiales,
      );
    } catch (e) {
      throw Exception('Error al cargar plantilla completa: $e');
    }
  }

  // ─── VALIDACIÓN DE NOMBRE ÚNICO ───────────────────────────────────────────

  /// True si ya existe otra plantilla con ese `nombre` (case-insensitive,
  /// trimmed). `excludeId` permite ignorar la plantilla en edición.
  /// En caso de error de red, retorna `false` para no bloquear el guardado
  /// — el constraint final lo enforcea la BD si se agrega.
  Future<bool> nombreYaExiste(String nombre, {String? excludeId}) async {
    try {
      final normalizado = nombre.trim().toLowerCase();
      final response = await _client
          .from('plantilla_prenda')
          .select('id_plantilla, nombre');
      final List items = response as List;
      return items.any((p) {
        final m = p as Map<String, dynamic>;
        final mismoNombre =
            (m['nombre'] as String).trim().toLowerCase() == normalizado;
        final esElMismo =
            excludeId != null && m['id_plantilla'].toString() == excludeId;
        return mismoNombre && !esElMismo;
      });
    } catch (_) {
      // TODO(plantillas-modulo): considerar logging del error.
      return false;
    }
  }

  // ─── CREAR PLANTILLA ──────────────────────────────────────────────────────

  Future<PlantillaModel> crearPlantilla({
    required String nombre,
    required int idTipoPrenda,
    required String especificaciones,
    required double precioPlantilla,
    required double tiempoProduccionUnitario,
    required List<int> tallasSeleccionadas,
    required List<MaterialPlantilla> materiales,
  }) async {
    try {
      final insertResponse = await _client
          .from('plantilla_prenda')
          .insert({
            'nombre': nombre,
            'id_tipo_prenda': idTipoPrenda,
            'especificaciones': especificaciones,
            'precio_plantilla': precioPlantilla,
            'tiempo_produccion_unitario': tiempoProduccionUnitario,
            'activo': true,
          })
          .select()
          .single();

      final idPlantilla = insertResponse['id_plantilla'].toString();

      // Insertar materiales
      final filasMateriales = [
        for (final m in materiales)
          {
            'id_plantilla': idPlantilla,
            'id_insumo': m.idInsumo,
            'cantidad_requerida': m.cantidad,
          },
      ];
      if (filasMateriales.isNotEmpty) {
        await _client.from('receta_material').insert(filasMateriales);
      }

      // Insertar tallas usando medida_ficha con valores por defecto
      final filasMedidas = [
        for (final idTalla in tallasSeleccionadas)
          {
            'id_plantilla': idPlantilla,
            'id_talla': idTalla,
            'nombre_medida': 'Base',
            'valor': 0.0,
          },
      ];
      if (filasMedidas.isNotEmpty) {
        await _client.from('medida_ficha').insert(filasMedidas);
      }

      return PlantillaModel.fromJson(insertResponse).copyWith(
        tallasSeleccionadas: tallasSeleccionadas,
        materiales: materiales,
      );
    } catch (e) {
      throw _traducirError(e);
    }
  }

  // ─── ACTUALIZAR PLANTILLA ─────────────────────────────────────────────────

  Future<PlantillaModel> actualizarPlantilla({
    required String id,
    required String nombre,
    required int idTipoPrenda,
    required String especificaciones,
    required double precioPlantilla,
    required double tiempoProduccionUnitario,
    required List<int> tallasSeleccionadas,
    required List<MaterialPlantilla> materiales,
  }) async {
    try {
      final actual = await _client
          .from('plantilla_prenda')
          .select('version')
          .eq('id_plantilla', id)
          .single();
      final versionActual = actual['version'] is int
          ? actual['version'] as int
          : int.tryParse(actual['version']?.toString() ?? '') ?? 1;
      final nuevaVersion = versionActual + 1;

      final updateResponse = await _client
          .from('plantilla_prenda')
          .update({
            'nombre': nombre,
            'id_tipo_prenda': idTipoPrenda,
            'especificaciones': especificaciones,
            'precio_plantilla': precioPlantilla,
            'tiempo_produccion_unitario': tiempoProduccionUnitario,
            'version': nuevaVersion,
          })
          .eq('id_plantilla', id)
          .select()
          .single();

      // Actualizar materiales
      await _client.from('receta_material').delete().eq('id_plantilla', id);
      final filasMateriales = [
        for (final m in materiales)
          {
            'id_plantilla': id,
            'id_insumo': m.idInsumo,
            'cantidad_requerida': m.cantidad,
          },
      ];
      if (filasMateriales.isNotEmpty) {
        await _client.from('receta_material').insert(filasMateriales);
      }

      // Actualizar tallas
      await _client.from('medida_ficha').delete().eq('id_plantilla', id);
      final filasMedidas = [
        for (final idTalla in tallasSeleccionadas)
          {
            'id_plantilla': id,
            'id_talla': idTalla,
            'nombre_medida': 'Base',
            'valor': 0.0,
          },
      ];
      if (filasMedidas.isNotEmpty) {
        await _client.from('medida_ficha').insert(filasMedidas);
      }

      return PlantillaModel.fromJson(updateResponse).copyWith(
        tallasSeleccionadas: tallasSeleccionadas,
        materiales: materiales,
      );
    } catch (e) {
      throw _traducirError(e);
    }
  }

  // ─── TOGGLE ACTIVA / INACTIVA ─────────────────────────────────────────────

  Future<PlantillaModel> toggleActiva(String id) async {
    try {
      final current = await _client
          .from('plantilla_prenda')
          .select('activo')
          .eq('id_plantilla', id)
          .single();
      final estadoActual = current['activo'] as bool? ?? true;

      final response = await _client
          .from('plantilla_prenda')
          .update({'activo': !estadoActual})
          .eq('id_plantilla', id)
          .select()
          .single();
      return PlantillaModel.fromJson(response);
    } catch (e) {
      throw Exception('Error al cambiar estado de plantilla: $e');
    }
  }

  // ─── SUGERENCIAS DE MEDIDAS (LOCAL) ───────────────────────────────────────

  // DECISIÓN: las sugerencias de medidas iniciales son una lista vacía.
  // RAZÓN: los tipos de prenda son volátiles (cambian en BD). No podemos
  // hardcodear sugerencias asociadas a IDs específicos porque se romperían.
  // El usuario agrega manualmente los puntos de medida que necesita.
  // CAMBIAR: cuando exista tabla `medida_estandar` con FK a tipo_prenda,
  // reemplazar este método por una query a esa tabla.
  // TODO Backend Mel: crear tabla
  //   medida_estandar(id_tipo_prenda int FK, nombre_medida text)
  // si quieren sugerencias automáticas por tipo de prenda.
  Future<List<MedidaPunto>> obtenerMedidasSugeridas(int idTipoPrenda) async {
    return const [];
  }

  // ─── HELPERS PRIVADOS ─────────────────────────────────────────────────────

  /// Traduce errores comunes de Supabase a mensajes amigables para el
  /// usuario. Por ahora solo cubre el caso del trigger de insumo inactivo.
  Exception _traducirError(Object error) {
    final msg = error.toString().toLowerCase();
    if (msg.contains('insumo') && msg.contains('activ')) {
      return Exception('No se puede usar un insumo inactivo en la receta.');
    }
    return Exception('Error al guardar plantilla: $error');
  }
}
