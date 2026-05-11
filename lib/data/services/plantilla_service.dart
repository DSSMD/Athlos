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
// TODO Backend Mel: crear funciones RPC en PostgreSQL para crear/actualizar
// plantilla con sus hijas en una sola transacción atómica.
//
// IMPORTANTE: existe trigger en receta_material que bloquea inserts con
// insumos inactivos. El service traduce ese error a un mensaje amigable.
// ============================================================================
//
// ============================================================================
// TODO Backend Mel: política de edición parcial
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

  /// Carga plantilla con sus medidas y materiales (para abrir el form en
  /// modo editar). Ejecuta 3 queries en paralelo.
  Future<PlantillaModel> obtenerPlantillaCompleta(String idPlantilla) async {
    try {
      // Future.wait con dynamic porque los builders de Supabase devuelven
      // tipos heterogéneos (Map / List) que la inferencia no puede unificar.
      final results = await Future.wait<dynamic>([
        _client
            .from('plantilla_prenda')
            .select()
            .eq('id_plantilla', idPlantilla)
            .single(),
        _client.from('medida_ficha').select().eq('id_plantilla', idPlantilla),
        _client
            .from('receta_material')
            .select()
            .eq('id_plantilla', idPlantilla),
      ]);

      final plantillaRaw = results[0] as Map<String, dynamic>;
      final medidasRaw = results[1] as List;
      final materialesRaw = results[2] as List;

      // Agrupar medidas por nombre_medida → una MedidaPunto por nombre.
      final Map<String, List<Map<String, dynamic>>> filasPorNombre = {};
      for (final fila in medidasRaw) {
        final map = fila as Map<String, dynamic>;
        final nombre = (map['nombre_medida'] ?? '') as String;
        filasPorNombre.putIfAbsent(nombre, () => []).add(map);
      }
      final medidas = filasPorNombre.entries
          .map(
            (e) => MedidaPunto.fromFilasSQL(
              idPlantilla: idPlantilla,
              nombreMedida: e.key,
              filas: e.value,
            ),
          )
          .toList();

      // Inferir tallas seleccionadas desde el conjunto de tallas usadas en
      // medidas. Si no hay medidas, queda vacío (el form lo dejará al
      // usuario seleccionarlas en Paso 2).
      final Set<int> tallasSet = {};
      for (final m in medidas) {
        tallasSet.addAll(m.valoresPorTalla.keys);
      }
      final tallas = tallasSet.toList()..sort();

      final materiales = materialesRaw
          .map((j) => MaterialPlantilla.fromJson(j as Map<String, dynamic>))
          .toList();

      return PlantillaModel.fromJson(plantillaRaw).copyWith(
        tallasSeleccionadas: tallas,
        medidas: medidas,
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

  /// Inserta plantilla + hijas en 3 pasos secuenciales. Si falla un paso,
  /// los anteriores quedan persistidos. Ver TODO Backend Mel del header.
  Future<PlantillaModel> crearPlantilla({
    required String nombre,
    required int idTipoPrenda,
    required String especificaciones,
    required List<int> tallasSeleccionadas,
    required List<MedidaPunto> medidas,
    required List<MaterialPlantilla> materiales,
  }) async {
    try {
      // Paso 1: INSERT plantilla_prenda. La version arranca en 1 (default
      // de la BD), id_plantilla y created_at los genera Postgres.
      final insertResponse = await _client
          .from('plantilla_prenda')
          .insert({
            'nombre': nombre,
            'id_tipo_prenda': idTipoPrenda,
            'especificaciones': especificaciones,
            'activo': true,
          })
          .select()
          .single();

      final idPlantilla = insertResponse['id_plantilla'].toString();

      // Paso 2: INSERT medida_ficha — una fila por (talla × medida).
      final filasMedidas = <Map<String, dynamic>>[
        for (final medida in medidas) ...medida.aFilasSQL(idPlantilla),
      ];
      if (filasMedidas.isNotEmpty) {
        await _client.from('medida_ficha').insert(filasMedidas);
      }

      // Paso 3: INSERT receta_material.
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

      return PlantillaModel.fromJson(insertResponse).copyWith(
        tallasSeleccionadas: tallasSeleccionadas,
        medidas: medidas,
        materiales: materiales,
      );
    } catch (e) {
      throw _traducirError(e);
    }
  }

  // ─── ACTUALIZAR PLANTILLA ─────────────────────────────────────────────────

  /// Estrategia: UPDATE plantilla_prenda (incrementando version) + DELETE
  /// total de las filas hijas + INSERT nuevas. No es transaccional —
  /// ver TODO Backend Mel del header.
  Future<PlantillaModel> actualizarPlantilla({
    required String id,
    required String nombre,
    required int idTipoPrenda,
    required String especificaciones,
    required List<int> tallasSeleccionadas,
    required List<MedidaPunto> medidas,
    required List<MaterialPlantilla> materiales,
  }) async {
    try {
      // Paso 1: leer version actual para incrementar.
      final actual = await _client
          .from('plantilla_prenda')
          .select('version')
          .eq('id_plantilla', id)
          .single();
      final versionActual = actual['version'] is int
          ? actual['version'] as int
          : int.tryParse(actual['version']?.toString() ?? '') ?? 1;
      final nuevaVersion = versionActual + 1;

      // Paso 2: UPDATE plantilla_prenda.
      final updateResponse = await _client
          .from('plantilla_prenda')
          .update({
            'nombre': nombre,
            'id_tipo_prenda': idTipoPrenda,
            'especificaciones': especificaciones,
            'version': nuevaVersion,
          })
          .eq('id_plantilla', id)
          .select()
          .single();

      // Paso 3: DELETE + INSERT en medida_ficha.
      await _client.from('medida_ficha').delete().eq('id_plantilla', id);
      final filasMedidas = <Map<String, dynamic>>[
        for (final medida in medidas) ...medida.aFilasSQL(id),
      ];
      if (filasMedidas.isNotEmpty) {
        await _client.from('medida_ficha').insert(filasMedidas);
      }

      // Paso 4: DELETE + INSERT en receta_material.
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

      return PlantillaModel.fromJson(updateResponse).copyWith(
        tallasSeleccionadas: tallasSeleccionadas,
        medidas: medidas,
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
