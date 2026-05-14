// ============================================================================
// lib/presentation/providers/plantilla_form_provider.dart
// ============================================================================
// State + Notifier scoped al modal del form multi-paso de Plantillas.
// - PlantillaFormState: snapshot inmutable con todos los campos del form
//   más metadatos (paso actual, modo crear/editar, id original)
// - PlantillaFormNotifier (autoDispose): expone setters por campo + helpers
//   de navegación entre pasos.
//
// Catálogos dinámicos: el form trabaja con IDs (idTipoPrenda: int,
// tallasSeleccionadas: List<int>). Los nombres se resuelven contra
// `tiposPrendaProvider` y `tallasProvider` en la UI.
//
// FLUJO PASO 1 (secuencial obligatorio):
//   1. categoriaPrenda (String?) — elige categoría primero.
//   2. idTipoPrenda    (int?)   — filtrado por categoría elegida.
//   3. nombre          (String) — nombre de la plantilla.
//   4. especificaciones (String) — descripción opcional.
// Al cambiar `categoriaPrenda`, `idTipoPrenda` se resetea automáticamente.
//
// DECISIÓN: autoDispose para que el state se limpie al cerrar el modal.
// RAZÓN: si el usuario cancela y vuelve a abrir, debe arrancar limpio.
// CAMBIAR: si quieren persistir borrador "draft" entre aperturas, sacar
// el autoDispose y agregar método limpiar() explícito.
// ============================================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/material_plantilla_model.dart';
import '../../domain/models/medida_punto_model.dart';
import '../../domain/models/plantilla_model.dart';

// ─── STATE ──────────────────────────────────────────────────────────────────

class PlantillaFormState {
  const PlantillaFormState({
    this.nombre = '',
    this.categoriaPrenda,
    this.idTipoPrenda,
    this.especificaciones = '',
    this.tallasSeleccionadas = const [],
    this.medidas = const [],
    this.materiales = const [],
    this.pasoActual = 0,
    this.mode = 'crear',
    this.plantillaOriginalId,
  });

  final String nombre;

  /// Categoría elegida en el Paso 1 (ej. 'Superior', 'Inferior').
  /// null hasta que el usuario la elija. Al cambiar, `idTipoPrenda`
  /// se resetea para evitar inconsistencias.
  final String? categoriaPrenda;

  final int? idTipoPrenda; // null hasta que el usuario lo elija
  final String especificaciones;
  final List<int> tallasSeleccionadas;
  final List<MedidaPunto> medidas;
  final List<MaterialPlantilla> materiales;

  /// 0..3 → Paso 1..4.
  final int pasoActual;

  /// `'crear'` o `'editar'`.
  final String mode;

  /// Id de la plantilla original cuando mode == 'editar'. Se usa para
  /// excluirla de la validación de nombre duplicado y para el UPDATE.
  final String? plantillaOriginalId;

  PlantillaFormState copyWith({
    String? nombre,
    // Para resetear categoriaPrenda a null usar clearCategoria: true.
    String? categoriaPrenda,
    bool clearCategoria = false,
    // Para resetear idTipoPrenda a null usar clearTipo: true.
    int? idTipoPrenda,
    bool clearTipo = false,
    String? especificaciones,
    List<int>? tallasSeleccionadas,
    List<MedidaPunto>? medidas,
    List<MaterialPlantilla>? materiales,
    int? pasoActual,
    String? mode,
    String? plantillaOriginalId,
  }) {
    return PlantillaFormState(
      nombre: nombre ?? this.nombre,
      categoriaPrenda:
          clearCategoria ? null : (categoriaPrenda ?? this.categoriaPrenda),
      idTipoPrenda: clearTipo ? null : (idTipoPrenda ?? this.idTipoPrenda),
      especificaciones: especificaciones ?? this.especificaciones,
      tallasSeleccionadas: tallasSeleccionadas ?? this.tallasSeleccionadas,
      medidas: medidas ?? this.medidas,
      materiales: materiales ?? this.materiales,
      pasoActual: pasoActual ?? this.pasoActual,
      mode: mode ?? this.mode,
      plantillaOriginalId: plantillaOriginalId ?? this.plantillaOriginalId,
    );
  }
}

// ─── NOTIFIER ───────────────────────────────────────────────────────────────

class PlantillaFormNotifier extends Notifier<PlantillaFormState> {
  @override
  PlantillaFormState build() => const PlantillaFormState();

  /// Resetea a un state vacío en modo `'crear'`.
  void inicializarParaCrear() {
    state = const PlantillaFormState(mode: 'crear');
  }

  /// Carga los campos de la plantilla en el state, en modo `'editar'`.
  /// [categoriaPrenda] debe resolverse en la UI buscando el tipo en el
  /// catálogo (ver plantilla_form_page.dart) y pasarse acá para que
  /// el dropdown de categoría quede preseleccionado.
  void inicializarParaEditar(PlantillaModel p, {String? categoriaPrenda}) {
    state = PlantillaFormState(
      mode: 'editar',
      plantillaOriginalId: p.id,
      nombre: p.nombre,
      categoriaPrenda: categoriaPrenda,
      idTipoPrenda: p.idTipoPrenda,
      especificaciones: p.especificaciones,
      tallasSeleccionadas: p.tallasSeleccionadas,
      medidas: p.medidas,
      materiales: p.materiales,
    );
  }

  // ─── SETTERS POR CAMPO ────────────────────────────────────────────────────

  void setNombre(String v) => state = state.copyWith(nombre: v);

  /// Cambia la categoría seleccionada y **resetea el tipo de prenda**
  /// para evitar que quede un tipo de otra categoría seleccionado.
  void setCategoriaPrenda(String? categoria) {
    if (categoria == state.categoriaPrenda) return;
    state = state.copyWith(
      categoriaPrenda: categoria,
      clearCategoria: categoria == null,
      clearTipo: true,
    );
  }

  void setIdTipoPrenda(int? id) =>
      state = state.copyWith(idTipoPrenda: id, clearTipo: id == null);

  void setEspecificaciones(String v) =>
      state = state.copyWith(especificaciones: v);

  /// Reemplaza la lista de tallas seleccionadas. Si alguna talla se quita,
  /// limpia su valor del Map `valoresPorTalla` de cada MedidaPunto — así
  /// no quedan valores fantasmas asociados a una talla deseleccionada.
  /// Los valores de las tallas que SIGUEN seleccionadas se preservan.
  void setTallasSeleccionadas(List<int> nuevasTallas) {
    final removidas = state.tallasSeleccionadas
        .where((id) => !nuevasTallas.contains(id))
        .toSet();

    final medidasLimpiadas = removidas.isEmpty
        ? state.medidas
        : state.medidas.map((m) {
            final nuevoMap = {
              for (final e in m.valoresPorTalla.entries)
                if (!removidas.contains(e.key)) e.key: e.value,
            };
            return m.copyWith(valoresPorTalla: nuevoMap);
          }).toList();

    state = state.copyWith(
      tallasSeleccionadas: nuevasTallas,
      medidas: medidasLimpiadas,
    );
  }

  void setMedidas(List<MedidaPunto> medidas) =>
      state = state.copyWith(medidas: medidas);

  void setMateriales(List<MaterialPlantilla> materiales) =>
      state = state.copyWith(materiales: materiales);

  // ─── SETTERS DE MEDIDAS (Paso 2) ──────────────────────────────────────────

  /// Genera un id temporal único usando microsegundos. Solo vive en el form;
  /// cuando se guarda en SQL, la BD genera el uuid real (medida_ficha.id_medida).
  String _nuevoIdTemp(String prefijo) =>
      '$prefijo-${DateTime.now().microsecondsSinceEpoch}';

  /// Agrega una MedidaPunto vacía al final de la lista.
  void agregarMedida() {
    final nueva = MedidaPunto(
      id: _nuevoIdTemp('medida'),
      nombre: '',
      valoresPorTalla: const {},
    );
    state = state.copyWith(medidas: [...state.medidas, nueva]);
  }

  void removerMedida(String idTemp) {
    state = state.copyWith(
      medidas: state.medidas.where((m) => m.id != idTemp).toList(),
    );
  }

  void setNombreMedida(String idTemp, String nuevoNombre) {
    state = state.copyWith(
      medidas: [
        for (final m in state.medidas)
          if (m.id == idTemp) m.copyWith(nombre: nuevoNombre) else m,
      ],
    );
  }

  /// Setea el valor de una talla en una medida. `null` o `0` elimina la
  /// entrada del Map (en vez de dejar el 0.0 como valor real).
  void setValorMedida(String idTemp, int idTalla, double? valor) {
    state = state.copyWith(
      medidas: [
        for (final m in state.medidas)
          if (m.id == idTemp)
            m.copyWith(
              valoresPorTalla: () {
                final nuevoMap = Map<int, double>.from(m.valoresPorTalla);
                if (valor == null || valor == 0) {
                  nuevoMap.remove(idTalla);
                } else {
                  nuevoMap[idTalla] = valor;
                }
                return nuevoMap;
              }(),
            )
          else
            m,
      ],
    );
  }

  // ─── SETTERS DE MATERIALES (Paso 3) ───────────────────────────────────────

  /// Agrega un MaterialPlantilla vacío al final de la lista.
  void agregarMaterial() {
    final nuevo = MaterialPlantilla(
      id: _nuevoIdTemp('mat'),
      idInsumo: '',
      cantidad: 0,
    );
    state = state.copyWith(materiales: [...state.materiales, nuevo]);
  }

  void removerMaterial(String idTemp) {
    state = state.copyWith(
      materiales: state.materiales.where((m) => m.id != idTemp).toList(),
    );
  }

  void setMaterialInsumo(String idTemp, String idInsumo) {
    state = state.copyWith(
      materiales: [
        for (final m in state.materiales)
          if (m.id == idTemp) m.copyWith(idInsumo: idInsumo) else m,
      ],
    );
  }

  void setMaterialCantidad(String idTemp, double cantidad) {
    state = state.copyWith(
      materiales: [
        for (final m in state.materiales)
          if (m.id == idTemp) m.copyWith(cantidad: cantidad) else m,
      ],
    );
  }

  // ─── NAVEGACIÓN ENTRE PASOS ───────────────────────────────────────────────

  // DECISIÓN: navegación solo lineal con Atrás/Siguiente.
  // RAZÓN: evita saltar pasos sin validar.
  // CAMBIAR: si quieren permitir saltar a pasos completados, hacer onTap
  // del indicator que llame irAPaso(N).
  void irAPaso(int p) {
    if (p < 0 || p > 3) return;
    state = state.copyWith(pasoActual: p);
  }

  void irSiguiente() {
    if (state.pasoActual < 3) {
      state = state.copyWith(pasoActual: state.pasoActual + 1);
    }
  }

  void irAtras() {
    if (state.pasoActual > 0) {
      state = state.copyWith(pasoActual: state.pasoActual - 1);
    }
  }

  // ─── DETECCIÓN DE CAMBIOS (para confirmación al cerrar) ───────────────────

  /// True si el usuario cargó algo que se perdería al cerrar el modal.
  /// - En modo `'crear'`: cualquier campo no vacío.
  /// - En modo `'editar'`: asume cambios siempre (conservador). Una
  ///   comparación profunda contra `initialPlantilla` sería más precisa
  ///   pero requiere acceso al modelo original — preferimos pedir
  ///   confirmación de más a perder datos por accidente.
  ///
  /// TODO(plantillas-modulo): si se quiere ser más preciso en modo
  /// editar, recibir el initialPlantilla en el notifier y comparar
  /// nombre/idTipoPrenda/especificaciones/tallas/medidas/materiales.
  bool tieneCambios() {
    final s = state;
    if (s.mode == 'crear') {
      return s.nombre.trim().isNotEmpty ||
          s.categoriaPrenda != null ||
          s.idTipoPrenda != null ||
          s.especificaciones.trim().isNotEmpty ||
          s.tallasSeleccionadas.isNotEmpty ||
          s.medidas.isNotEmpty ||
          s.materiales.isNotEmpty;
    }
    return true;
  }
}

// ─── PROVIDER ───────────────────────────────────────────────────────────────

final plantillaFormStateProvider =
    NotifierProvider.autoDispose<PlantillaFormNotifier, PlantillaFormState>(
      PlantillaFormNotifier.new,
    );
