// ============================================================================
// lib/presentation/pages/admin/plantillas/widgets/plantilla_form_paso1_info.dart
// ============================================================================
// Paso 1 del form multi-paso de Plantillas — Información general.
//
// FLUJO SECUENCIAL OBLIGATORIO:
//   1. Categoría de prenda  (dropdown) — siempre habilitado.
//   2. Tipo de prenda       (dropdown) — habilitado solo con categoría elegida,
//                                        items filtrados por esa categoría.
//   3. Nombre de la plantilla (text)  — habilitado solo con tipo elegido.
//   4. Especificaciones     (text)    — siempre disponible (campo opcional).
//
// Si el usuario cambia la categoría, el tipo se resetea automáticamente
// (lo maneja `PlantillaFormNotifier.setCategoriaPrenda` en el provider).
// Si el tipo se resetea, el campo nombre vuelve a quedar deshabilitado.
//
// El padre (PlantillaFormPage) pasa un GlobalKey<FormState> y llama
// key.currentState!.validate() antes de avanzar al Paso 2.
// State persiste en plantillaFormStateProvider — al volver al Paso 1
// desde otro paso, los datos se mantienen.
//
// DECISIÓN: el form padre controla la validación llamando al hijo.
// RAZÓN: el padre coordina la navegación, el hijo valida sus propios campos.
// CAMBIAR: si los pasos crecen mucho, considerar mover validación al notifier.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../providers/catalogos_provider.dart';
import '../../../../providers/plantilla_form_provider.dart';
import '../../../../providers/plantilla_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';

class PlantillaFormPaso1Info extends ConsumerStatefulWidget {
  const PlantillaFormPaso1Info({super.key, required this.formKey});

  /// Key del Form interno — el padre lo usa para invocar `validate()` antes
  /// de avanzar al Paso 2.
  final GlobalKey<FormState> formKey;

  @override
  ConsumerState<PlantillaFormPaso1Info> createState() =>
      _PlantillaFormPaso1InfoState();
}

class _PlantillaFormPaso1InfoState
    extends ConsumerState<PlantillaFormPaso1Info> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _especificacionesCtrl;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(plantillaFormStateProvider);
    _nombreCtrl = TextEditingController(text: initial.nombre);
    _especificacionesCtrl = TextEditingController(
      text: initial.especificaciones,
    );
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _especificacionesCtrl.dispose();
    super.dispose();
  }

  // ─── VALIDADORES ──────────────────────────────────────────────────────────

  String? _validarNombre(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return 'El nombre es requerido';
    if (raw.length > 100) return 'Máximo 100 caracteres';
    final formState = ref.read(plantillaFormStateProvider);
    final yaExiste = ref
        .read(plantillaProvider.notifier)
        .nombreYaExiste(raw, excludeId: formState.plantillaOriginalId);
    if (yaExiste) return 'Ya existe una plantilla con este nombre';
    return null;
  }

  String? _validarEspecificaciones(String? value) {
    if ((value ?? '').length > 1000) return 'Máximo 1000 caracteres';
    return null;
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(plantillaFormStateProvider);
    final notifier = ref.read(plantillaFormStateProvider.notifier);
    final tiposPrendaAsync = ref.watch(tiposPrendaProvider);
    final categoriasAsync = tiposPrendaAsync.whenData(
      (tipos) => tipos.map((t) => t.categoria).toSet().toList()..sort(),
    );

    // Sincroniza controllers cuando el state cambia desde afuera (ej.
    // inicialización por postFrameCallback en modo editar). Compara
    // antes de setear para no perder la posición del cursor mientras
    // el usuario tipea (los cambios que vienen DEL usuario ya están
    // en el controller, igualan al state nuevo, y no se re-setean).
    ref.listen<PlantillaFormState>(plantillaFormStateProvider, (prev, next) {
      if (_nombreCtrl.text != next.nombre) {
        _nombreCtrl.text = next.nombre;
      }
      if (_especificacionesCtrl.text != next.especificaciones) {
        _especificacionesCtrl.text = next.especificaciones;
      }
    });

    // ─── Estado derivado de la secuencia ──────────────────────────────────
    final categoriaElegida = state.categoriaPrenda;
    final tipoElegido = state.idTipoPrenda;
    final tieneCategoria = categoriaElegida != null;
    final tieneTipo = tipoElegido != null;

    // Tipos filtrados por la categoría seleccionada.
    final tiposFiltrados = tiposPrendaAsync.whenOrNull(
          data: (tipos) => tieneCategoria
              ? tipos.where((t) => t.categoria == categoriaElegida).toList()
              : <dynamic>[],
        ) ??
        <dynamic>[];

    return Form(
      key: widget.formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── PASO A: Categoría ────────────────────────────────────────
            _label('Categoría de prenda *'),
            categoriasAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text(
                'Error al cargar categorías: $e',
                style: AppTypography.small.copyWith(color: AppColors.error),
              ),
              data: (categorias) {
                // Sanitizo el value: si la categoría del state no está en el
                // catálogo actual, paso null para evitar el assert del Dropdown.
                final valorActual = categorias.contains(categoriaElegida)
                    ? categoriaElegida
                    : null;

                final dropdownKey = ValueKey(
                  'cat-${state.mode}-${state.plantillaOriginalId ?? "new"}',
                );

                return DropdownButtonFormField<String>(
                  key: dropdownKey,
                  initialValue: valorActual,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    hintText: 'Seleccioná una categoría',
                  ),
                  items: categorias
                      .map(
                        (c) => DropdownMenuItem<String>(
                          value: c,
                          child: Text(c),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => notifier.setCategoriaPrenda(v),
                  validator: (v) =>
                      v == null ? 'Seleccioná una categoría de prenda' : null,
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // ── PASO B: Tipo de prenda (bloqueado sin categoría) ─────────
            _label(
              'Tipo de prenda *',
              hint: !tieneCategoria ? 'Primero seleccioná una categoría' : null,
            ),
            tiposPrendaAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text(
                'Error al cargar tipos: $e',
                style: AppTypography.small.copyWith(color: AppColors.error),
              ),
              data: (tipos) {
                // Sanitizo el value: si el idTipoPrenda del state no está en
                // los tipos filtrados por la categoría actual, paso null.
                final valorActual = tiposFiltrados.any((t) {
                      // tiposFiltrados es List<TipoPrendaModel> en tiempo real
                      // pero tipado como List<dynamic> por el whenOrNull.
                      // Acceso seguro con cast dinámico.
                      return (t as dynamic).id == tipoElegido;
                    })
                    ? tipoElegido
                    : null;

                // Key cambia cuando cambia la categoría (para forzar remount
                // del FormField y limpiar visualmente el item seleccionado).
                final dropdownKey = ValueKey(
                  'tipo-${state.mode}-'
                  '${state.plantillaOriginalId ?? "new"}-$categoriaElegida',
                );

                return DropdownButtonFormField<int>(
                  key: dropdownKey,
                  initialValue: valorActual,
                  isExpanded: true,
                  // Deshabilitar si no hay categoría seleccionada.
                  onChanged: tieneCategoria
                      ? (v) {
                          if (v != null) notifier.setIdTipoPrenda(v);
                        }
                      : null,
                  decoration: InputDecoration(
                    hintText: tieneCategoria
                        ? 'Seleccioná un tipo'
                        : 'Primero seleccioná una categoría',
                    // Estilo visual de "deshabilitado" sin perder estructura.
                    fillColor: tieneCategoria
                        ? null
                        : AppColors.neutral100,
                  ),
                  items: tiposFiltrados
                      .cast<dynamic>()
                      .map(
                        (t) => DropdownMenuItem<int>(
                          value: (t as dynamic).id as int,
                          child: Text((t as dynamic).nombre as String),
                        ),
                      )
                      .toList(),
                  validator: (v) =>
                      v == null ? 'Seleccioná un tipo de prenda' : null,
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // ── PASO C: Nombre (bloqueado sin tipo) ──────────────────────
            _label(
              'Nombre de la plantilla *',
              hint: !tieneTipo ? 'Primero seleccioná el tipo de prenda' : null,
            ),
            TextFormField(
              controller: _nombreCtrl,
              maxLength: 100,
              enabled: tieneTipo,
              decoration: InputDecoration(
                hintText: tieneTipo
                    ? 'Ej: Camisa Manga Larga Clásica'
                    : 'Primero seleccioná el tipo de prenda',
                fillColor: tieneTipo ? null : AppColors.neutral100,
              ),
              onChanged: tieneTipo ? notifier.setNombre : null,
              validator: tieneTipo ? _validarNombre : null,
            ),
            const SizedBox(height: AppSpacing.md),

            // ── PASO D: Especificaciones (siempre disponible, opcional) ──
            _label('Especificaciones (opcional)'),
            TextFormField(
              controller: _especificacionesCtrl,
              maxLines: 5,
              minLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(
                hintText:
                    'Notas técnicas, detalles de confección, observaciones...',
              ),
              onChanged: notifier.setEspecificaciones,
              validator: _validarEspecificaciones,
            ),
          ],
        ),
      ),
    );
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  /// Devuelve el widget de label. Si [hint] no es null, lo muestra como
  /// subtexto en color muted para guiar al usuario sobre qué hacer primero.
  Widget _label(String text, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: AppTypography.small.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(
              hint,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
