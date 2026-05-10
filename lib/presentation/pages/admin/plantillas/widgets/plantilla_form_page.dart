// ============================================================================
// lib/presentation/pages/admin/plantillas/widgets/plantilla_form_page.dart
// ============================================================================
// Modal del form multi-paso de Plantillas. UN modal único con stepper
// interno de 4 pasos (no 4 vistas separadas).
// - Helper público: showPlantillaFormPage(context, {mode, initialPlantilla})
// - Desktop (>=900): Dialog centrado con maxWidth 640
// - Mobile (<900): Scaffold full-screen
// - Header: título dinámico + botón X cerrar
// - Stepper visual: 4 indicadores numerados con label, conector entre ellos
// - Body: IndexedStack de los 4 pasos (preserva el state de cada uno)
// - Footer: Cancelar / ← Atrás / Siguiente → / Guardar
//
// El form es un IndexedStack para preservar el state de cada paso al
// navegar. El state real vive en plantillaFormStateProvider (autoDispose),
// no en los widgets de pasos individuales — esto evita perder datos al ir
// y volver.
//
// DECISIÓN: stepper visual hardcoded acá. RAZÓN: control total del estilo,
// alineado con el resto del proyecto. CAMBIAR: si quieren usar Stepper de
// Material 3, reemplazar este widget.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/models/plantilla_model.dart';
import '../../../../providers/plantilla_form_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';

import 'plantilla_form_paso1_info.dart';
import 'plantilla_form_paso2_medidas.dart';
import 'plantilla_form_paso3_materiales.dart';
import 'plantilla_form_paso4_resumen.dart';

// ─── HELPER PÚBLICO ─────────────────────────────────────────────────────────

/// Abre el modal del form multi-paso.
/// - [mode] = `'crear'` | `'editar'`. Default `'crear'`.
/// - [initialPlantilla] requerido si `mode == 'editar'`.
///
/// DECISIÓN: la inicialización del state ocurre ACÁ, en el helper, ANTES
/// de mostrar el modal — usando `ProviderScope.containerOf(context).read`.
/// RAZÓN: Riverpod 3 prohibe modificar providers durante el build del árbol
/// de widgets, así que no se puede hacer en initState (se rompía con
/// "Tried to modify a provider while the widget tree was building").
/// La opción de `addPostFrameCallback` tampoco sirve acá porque
/// PlantillaFormPaso1Info crea sus TextEditingController en su propio
/// initState leyendo el state — si el state aún no está inicializado en
/// ese momento, los controllers nacen vacíos y no se re-sincronizan.
/// CAMBIAR: si en el futuro el form deja de depender de controllers
/// inicializados desde state (ej. campos no controlados), se puede volver
/// a la opción más idiomática con notifier en initState + postFrameCallback.
Future<void> showPlantillaFormPage(
  BuildContext context, {
  String mode = 'crear',
  PlantillaModel? initialPlantilla,
}) {
  assert(
    mode == 'crear' || mode == 'editar',
    'mode debe ser "crear" o "editar"',
  );
  assert(
    !(mode == 'crear' && initialPlantilla != null),
    'En modo "crear" no debe pasarse initialPlantilla',
  );
  assert(
    !(mode == 'editar' && initialPlantilla == null),
    'En modo "editar" debe pasarse initialPlantilla',
  );

  // Inicializar el state ANTES de abrir el modal. Importante: el
  // provider es autoDispose, así que mientras nadie lo escuche se
  // dispone. Pero la `read` siguiente pone state que sobrevive sólo lo
  // suficiente: en cuanto el widget del modal hace `ref.watch`, el
  // listener se registra y el state que pusimos acá se mantiene.
  final container = ProviderScope.containerOf(context);
  final notifier = container.read(plantillaFormStateProvider.notifier);
  if (mode == 'editar') {
    notifier.inicializarParaEditar(initialPlantilla!);
  } else {
    notifier.inicializarParaCrear();
  }

  final isMobile = MediaQuery.of(context).size.width < 900;

  if (isMobile) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _PlantillaFormScaffold(
          isMobile: true,
          mode: mode,
          initialPlantilla: initialPlantilla,
        ),
      ),
    );
  }
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640, maxHeight: 720),
        child: _PlantillaFormScaffold(
          isMobile: false,
          mode: mode,
          initialPlantilla: initialPlantilla,
        ),
      ),
    ),
  );
}

// ─── SCAFFOLD INTERNO ───────────────────────────────────────────────────────

class _PlantillaFormScaffold extends ConsumerStatefulWidget {
  const _PlantillaFormScaffold({
    required this.isMobile,
    required this.mode,
    required this.initialPlantilla,
  });

  final bool isMobile;
  final String mode;
  final PlantillaModel? initialPlantilla;

  @override
  ConsumerState<_PlantillaFormScaffold> createState() =>
      _PlantillaFormScaffoldState();
}

class _PlantillaFormScaffoldState
    extends ConsumerState<_PlantillaFormScaffold> {
  // Key del Form del Paso 1 — vive acá para que el padre coordine el
  // validate() antes de avanzar al Paso 2.
  //
  // El state del provider ya viene inicializado por showPlantillaFormPage()
  // antes de que este scaffold se construya. No tocamos el provider en
  // initState para no chocar con la regla de Riverpod 3 que prohibe
  // modificar providers durante el build del árbol de widgets.
  final GlobalKey<FormState> _paso1FormKey = GlobalKey<FormState>();

  // ─── ACCIONES ─────────────────────────────────────────────────────────────

  void _onCancelar() {
    // TODO(plantillas-modulo): confirmación "cambios sin guardar" — Bloque 4.
    Navigator.of(context).pop();
  }

  void _onSiguiente() {
    final paso = ref.read(plantillaFormStateProvider).pasoActual;
    if (paso == 0) {
      final ok = _paso1FormKey.currentState?.validate() ?? false;
      if (!ok) return;
    }
    // Pasos 2/3 son placeholders — siempre permite avanzar por ahora.
    ref.read(plantillaFormStateProvider.notifier).irSiguiente();
  }

  void _onAtras() {
    ref.read(plantillaFormStateProvider.notifier).irAtras();
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(plantillaFormStateProvider);
    final paso = state.pasoActual;

    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(
          mode: widget.mode,
          nombreOriginal: widget.initialPlantilla?.nombre,
          onClose: _onCancelar,
        ),
        const Divider(height: 1, color: AppColors.border),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
          child: _Stepper(pasoActual: paso),
        ),
        const Divider(height: 1, color: AppColors.border),
        Expanded(
          child: IndexedStack(
            index: paso,
            children: [
              PlantillaFormPaso1Info(formKey: _paso1FormKey),
              const PlantillaFormPaso2Medidas(),
              const PlantillaFormPaso3Materiales(),
              const PlantillaFormPaso4Resumen(),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        _Footer(
          pasoActual: paso,
          onCancelar: _onCancelar,
          onAtras: _onAtras,
          onSiguiente: _onSiguiente,
        ),
      ],
    );

    if (widget.isMobile) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: body),
      );
    }
    return body;
  }
}

// ─── HEADER ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.mode,
    required this.nombreOriginal,
    required this.onClose,
  });

  final String mode;
  final String? nombreOriginal;
  final VoidCallback onClose;

  String get _titulo {
    if (mode == 'editar' && nombreOriginal != null) {
      return 'Editar Plantilla: $nombreOriginal';
    }
    return 'Nueva Plantilla';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _titulo,
              style: AppTypography.h2,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: onClose,
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }
}

// ─── STEPPER ────────────────────────────────────────────────────────────────

class _Stepper extends StatelessWidget {
  const _Stepper({required this.pasoActual});

  final int pasoActual;

  static const _labels = ['Info', 'Medidas', 'Materiales', 'Resumen'];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < 4; i++) ...[
          _StepCircle(index: i, pasoActual: pasoActual, label: _labels[i]),
          if (i < 3)
            Expanded(child: _Connector(pasoActual: pasoActual, indexAfter: i)),
        ],
      ],
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.index,
    required this.pasoActual,
    required this.label,
  });

  final int index;
  final int pasoActual;
  final String label;

  @override
  Widget build(BuildContext context) {
    final isCompleted = index < pasoActual;
    final isActive = index == pasoActual;

    final Color bg;
    final Color fg;
    final Widget child;

    if (isCompleted) {
      bg = AppColors.success;
      fg = AppColors.brandWhite;
      child = const Icon(Icons.check, size: 16, color: AppColors.brandWhite);
    } else if (isActive) {
      bg = AppColors.primary500;
      fg = AppColors.brandWhite;
      child = Text(
        '${index + 1}',
        style: AppTypography.small.copyWith(
          color: AppColors.brandWhite,
          fontWeight: FontWeight.w600,
        ),
      );
    } else {
      bg = AppColors.neutral100;
      fg = AppColors.textMuted;
      child = Text(
        '${index + 1}',
        style: AppTypography.small.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
          child: child,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: fg,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector({required this.pasoActual, required this.indexAfter});

  /// Conector que sigue al círculo `indexAfter` (entre indexAfter e
  /// indexAfter+1). Verde si el círculo previo ya está completado.
  final int pasoActual;
  final int indexAfter;

  @override
  Widget build(BuildContext context) {
    final completed = indexAfter < pasoActual;
    return Padding(
      // Centrar el conector con la altura del círculo (28/2 = 14, menos
      // la mitad de su propio thickness 2 = 1) — simplificado a 13.
      padding: const EdgeInsets.only(bottom: 22),
      child: Container(
        height: 2,
        color: completed ? AppColors.success : AppColors.border,
      ),
    );
  }
}

// ─── FOOTER ─────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  const _Footer({
    required this.pasoActual,
    required this.onCancelar,
    required this.onAtras,
    required this.onSiguiente,
  });

  final int pasoActual;
  final VoidCallback onCancelar;
  final VoidCallback onAtras;
  final VoidCallback onSiguiente;

  @override
  Widget build(BuildContext context) {
    final esUltimo = pasoActual == 3;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          TextButton(onPressed: onCancelar, child: const Text('Cancelar')),
          const Spacer(),
          if (pasoActual > 0)
            OutlinedButton.icon(
              onPressed: onAtras,
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Atrás'),
            ),
          const SizedBox(width: AppSpacing.sm),
          if (!esUltimo)
            FilledButton.icon(
              onPressed: onSiguiente,
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('Siguiente'),
            )
          else
            // TODO(plantillas-modulo): habilitar y conectar a
            // crearPlantilla / actualizarPlantilla en Bloque 4.
            const FilledButton(
              onPressed: null,
              child: Text('Guardar'),
            ),
        ],
      ),
    );
  }
}
