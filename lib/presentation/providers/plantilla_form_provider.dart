// ============================================================================
// lib/presentation/providers/plantilla_form_provider.dart
// ============================================================================
// State + Notifier scoped al modal del form multi-paso de Plantillas.
// - PlantillaFormState: snapshot inmutable con todos los campos del form
//   más metadatos (paso actual, modo crear/editar, id original)
// - PlantillaFormNotifier (AutoDispose): expone setters por campo + helpers
//   de navegación entre pasos.
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
    this.tipoPrenda,
    this.especificaciones = '',
    this.tallasSeleccionadas = const [],
    this.medidas = const [],
    this.materiales = const [],
    this.pasoActual = 0,
    this.mode = 'crear',
    this.plantillaOriginalId,
  });

  final String nombre;
  final TipoPrenda? tipoPrenda;
  final String especificaciones;
  final List<TallaPrenda> tallasSeleccionadas;
  final List<MedidaPunto> medidas;
  final List<MaterialPlantilla> materiales;

  /// 0..3 → Paso 1..4.
  final int pasoActual;

  /// `'crear'` o `'editar'`.
  final String mode;

  /// Id de la plantilla original cuando mode == 'editar'. Se usa para
  /// excluirla de la validación de nombre duplicado.
  final String? plantillaOriginalId;

  PlantillaFormState copyWith({
    String? nombre,
    TipoPrenda? tipoPrenda,
    String? especificaciones,
    List<TallaPrenda>? tallasSeleccionadas,
    List<MedidaPunto>? medidas,
    List<MaterialPlantilla>? materiales,
    int? pasoActual,
    String? mode,
    String? plantillaOriginalId,
  }) {
    return PlantillaFormState(
      nombre: nombre ?? this.nombre,
      tipoPrenda: tipoPrenda ?? this.tipoPrenda,
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
  void inicializarParaEditar(PlantillaModel p) {
    state = PlantillaFormState(
      mode: 'editar',
      plantillaOriginalId: p.id,
      nombre: p.nombre,
      tipoPrenda: p.tipoPrenda,
      especificaciones: p.especificaciones,
      tallasSeleccionadas: p.tallasSeleccionadas,
      medidas: p.medidas,
      materiales: p.materiales,
    );
  }

  // ─── SETTERS POR CAMPO ────────────────────────────────────────────────────

  void setNombre(String v) => state = state.copyWith(nombre: v);

  // copyWith no acepta `null` para tipoPrenda (queda como ?? this.tipoPrenda),
  // pero el form solo cambia el tipo a un valor válido — nunca a null.
  void setTipoPrenda(TipoPrenda v) => state = state.copyWith(tipoPrenda: v);

  void setEspecificaciones(String v) =>
      state = state.copyWith(especificaciones: v);

  void setTallasSeleccionadas(List<TallaPrenda> tallas) =>
      state = state.copyWith(tallasSeleccionadas: tallas);

  void setMedidas(List<MedidaPunto> medidas) =>
      state = state.copyWith(medidas: medidas);

  void setMateriales(List<MaterialPlantilla> materiales) =>
      state = state.copyWith(materiales: materiales);

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
}

// ─── PROVIDER ───────────────────────────────────────────────────────────────

final plantillaFormStateProvider =
    NotifierProvider.autoDispose<
      PlantillaFormNotifier,
      PlantillaFormState
    >(PlantillaFormNotifier.new);
