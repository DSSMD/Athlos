// ============================================================================
// lib/presentation/pages/admin/plantillas/widgets/plantilla_form_paso1_info.dart
// ============================================================================
// Paso 1 del form multi-paso de Plantillas — Información general.
// - 3 campos: nombre (req), tipo de prenda (req), especificaciones (opcional)
// - El padre (PlantillaFormPage) pasa un GlobalKey<FormState> y llama
//   key.currentState!.validate() antes de avanzar al Paso 2.
// - State persiste en plantillaFormStateProvider — al volver al Paso 1
//   desde otro paso, los datos se mantienen.
//
// Tipo de prenda: dropdown dinámico contra `tiposPrendaProvider`. Si el
// catálogo aún está cargando, se muestra un loading inline; si falla, un
// mensaje de error.
//
// DECISIÓN: el form padre controla la validación llamando al hijo. RAZÓN:
// el padre coordina la navegación, el hijo valida sus propios campos.
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

    return Form(
      key: widget.formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _label('Nombre de la prenda *'),
            TextFormField(
              controller: _nombreCtrl,
              maxLength: 100,
              decoration: const InputDecoration(
                hintText: 'Ej: Camisa Manga Larga Clásica',
              ),
              onChanged: notifier.setNombre,
              validator: _validarNombre,
            ),
            const SizedBox(height: AppSpacing.md),
            _label('Tipo de prenda *'),
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
                // el catálogo actual (por ejemplo, fue eliminado de la BD),
                // paso null para evitar el assert de Dropdown.
                final valorActual = tipos.any((t) => t.id == state.idTipoPrenda)
                    ? state.idTipoPrenda
                    : null;
                // Key del FormField cambia cuando state.mode/originalId
                // varía (transición crear→editar o cambio de plantilla).
                // Esto fuerza remount del FormField para que tome el nuevo
                // initialValue — necesario porque FormField solo lee
                // initialValue en su propio initState.
                final dropdownKey = ValueKey(
                  'tipo-${state.mode}-${state.plantillaOriginalId ?? "new"}',
                );
                return DropdownButtonFormField<int>(
                  key: dropdownKey,
                  initialValue: valorActual,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    hintText: 'Seleccioná un tipo',
                  ),
                  items: tipos
                      .map(
                        (t) => DropdownMenuItem<int>(
                          value: t.id,
                          child: Text(t.nombre),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) notifier.setIdTipoPrenda(v);
                  },
                  validator: (v) =>
                      v == null ? 'Seleccioná un tipo de prenda' : null,
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
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

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text,
        style: AppTypography.small.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
