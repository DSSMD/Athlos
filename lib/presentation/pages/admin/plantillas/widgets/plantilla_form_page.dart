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
import '../../../../providers/catalogos_provider.dart';
import '../../../../providers/plantilla_form_provider.dart';
import '../../../../providers/plantilla_provider.dart';
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
/// DECISIÓN: la inicialización del state se hace en el `initState` del
/// scaffold con `addPostFrameCallback`, NO acá antes de abrir el modal.
/// RAZÓN: el provider es `autoDispose`. Si inicializamos acá con
/// `container.read(notifier)`, no hay listeners y entre el read y el
/// primer `ref.watch` del modal el provider se dispone vía microtask,
/// perdiendo el state inicializado (bug A.1 del Bloque 6). Inicializar
/// con `addPostFrameCallback` espera al primer frame, momento en que
/// el modal ya está montado y escuchando, asegurando que el state
/// inicializado persiste. Los hijos que ya hicieron initState con state
/// vacío se sincronizan vía `ref.listen` (ver paso1_info.dart).
/// CAMBIAR: si en el futuro Riverpod 3 cambia el timing del autoDispose,
/// se puede volver a la versión sincrónica en el helper.
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
  final GlobalKey<FormState> _paso1FormKey = GlobalKey<FormState>();

  // Key del ScaffoldMessenger local al modal. Sin esto,
  // `ScaffoldMessenger.of(context)` puede resolver al messenger global de
  // la app (detrás del Dialog) y el SnackBar aparece duplicado o invisible.
  // Con la key invocamos directamente el messenger local del modal.
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();

  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    // Inicialización del state vía postFrame: corre DESPUÉS del primer
    // frame, cuando ya hay listeners activos del provider (el modal
    // hizo ref.watch). Esto evita la race condition de autoDispose con
    // la versión sincrónica anterior.
    //
    // Los pasos hijos cuyo initState lee state vacío en ese primer
    // frame (ej. Paso 1 con controllers) se sincronizan via ref.listen.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(plantillaFormStateProvider.notifier);
      if (widget.mode == 'editar' && widget.initialPlantilla != null) {
        // Resolver la categoriaPrenda desde el catálogo ya cargado.
        // Si el catálogo aún no cargó, la categoría quedará null y el
        // dropdown de categoría mostrará "sin categoría" — aceptable porque
        // el usuario puede re-seleccionarla. En la práctica el catálogo
        // ya está cacheado (FutureProvider sin autoDispose) cuando se
        // llega a abrir el modal en modo editar.
        final tiposAsync = ref.read(tiposPrendaProvider);
        final idTipo = widget.initialPlantilla!.idTipoPrenda;
        final categoriaPrenda = tiposAsync.whenOrNull(
          data: (tipos) {
            return tipos
                .where((t) => t.id == idTipo)
                .firstOrNull
                ?.categoria;
          },
        );
        notifier.inicializarParaEditar(
          widget.initialPlantilla!,
          categoriaPrenda: categoriaPrenda,
        );
      } else {
        notifier.inicializarParaCrear();
      }
    });
  }

  // ─── ACCIONES ─────────────────────────────────────────────────────────────

  /// Cierra el modal. Si hay cambios sin guardar pide confirmación; si no,
  /// pop directo. Lo usan tanto el botón X del header como Cancelar del
  /// footer.
  Future<void> _onCancelar() async {
    final tieneCambios = ref
        .read(plantillaFormStateProvider.notifier)
        .tieneCambios();

    if (!tieneCambios) {
      Navigator.of(context).pop();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('¿Descartar cambios?'),
        content: const Text(
          'Si salís ahora, los datos cargados se perderán y no se '
          'guardará la plantilla.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Seguir editando'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  void _onSiguiente() {
    final state = ref.read(plantillaFormStateProvider);
    final paso = state.pasoActual;

    if (paso == 0) {
      // Paso 1 → 2: validar el Form (nombre + tipo + especificaciones).
      final ok = _paso1FormKey.currentState?.validate() ?? false;
      if (!ok) return;
    } else if (paso == 1) {
      // Paso 2 → 3: exigir tallas.
      if (state.tallasSeleccionadas.isEmpty) {
        _messengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Seleccioná al menos una talla antes de avanzar.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
    } else if (paso == 2) {
      // Paso 3 → 4: exigir al menos UN material, y todos completos.
      if (state.materiales.isEmpty) {
        _messengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Agregá al menos un material.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }

      final incompletos = state.materiales.where(
        (m) => m.idInsumo.isEmpty || m.cantidad <= 0,
      );
      if (incompletos.isNotEmpty) {
        _messengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text(
              'Completá todos los materiales (insumo y cantidad > 0) '
              'o eliminalos antes de avanzar.',
            ),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
    }

    ref.read(plantillaFormStateProvider.notifier).irSiguiente();
  }

  void _onAtras() {
    ref.read(plantillaFormStateProvider.notifier).irAtras();
  }

  /// Guardado del Paso 4. Muestra confirm dialog, llama a crearPlantilla
  /// o actualizarPlantilla según el modo, y cierra el modal con SnackBar.
  /// El optimistic update del listado lo maneja el notifier — no hace
  /// falta `ref.invalidate(plantillaProvider)` acá.
  Future<void> _onGuardar() async {
    final state = ref.read(plantillaFormStateProvider);
    final mode = widget.mode;
    final initial = widget.initialPlantilla;

    // Sanity check: el botón sólo se habilita en Paso 4, pero por las
    // dudas validamos que los campos obligatorios estén OK. Para esto
    // re-corremos el validate del Paso 1.
    if (state.idTipoPrenda == null || state.nombre.trim().isEmpty) {
      _messengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text(
            'Faltan datos obligatorios. Volvé al Paso 1 para completarlos.',
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('¿Guardar plantilla?'),
        content: Text(
          mode == 'crear'
              ? 'Se creará la plantilla "${state.nombre}". '
                    'Podrás agregar medidas y materiales luego editándola.'
              : 'Se actualizará la plantilla "${state.nombre}" '
                    'a la versión v${(initial!.version) + 1}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _guardando = true);

    try {
      final insumos = ref.read(insumosProvider).value ?? [];
      double precioTotal = 0.0;
      for (final m in state.materiales) {
        final insumo = insumos.where((i) => i.id == m.idInsumo).firstOrNull;
        if (insumo != null) {
          precioTotal += m.cantidad * insumo.costoUnitario;
        }
      }

      if (mode == 'crear') {
        await ref
            .read(plantillaProvider.notifier)
            .crearPlantilla(
              nombre: state.nombre,
              idTipoPrenda: state.idTipoPrenda!,
              especificaciones: state.especificaciones,
              precioPlantilla: precioTotal,
              tallasSeleccionadas: state.tallasSeleccionadas,
              materiales: state.materiales,
            );
      } else {
        await ref
            .read(plantillaProvider.notifier)
            .actualizarPlantilla(
              id: initial!.id,
              nombre: state.nombre,
              idTipoPrenda: state.idTipoPrenda!,
              especificaciones: state.especificaciones,
              precioPlantilla: precioTotal,
              tallasSeleccionadas: state.tallasSeleccionadas,
              materiales: state.materiales,
            );
      }

      if (!mounted) return;
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            mode == 'crear'
                ? 'Plantilla creada correctamente'
                : 'Plantilla actualizada correctamente',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _messengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
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
              PlantillaFormPaso4Resumen(
                initialPlantilla: widget.initialPlantilla,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        _Footer(
          pasoActual: paso,
          onCancelar: _onCancelar,
          onAtras: _onAtras,
          onSiguiente: _onSiguiente,
          onGuardar: _onGuardar,
          guardando: _guardando,
        ),
      ],
    );

    if (widget.isMobile) {
      return ScaffoldMessenger(
        key: _messengerKey,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(child: body),
        ),
      );
    }
    // Desktop: envolver en ScaffoldMessenger + Scaffold para que el modal
    // tenga su propio messenger local. Sin esto, los SnackBars escalan al
    // messenger global de la app y aparecen duplicados o invisibles
    // detrás del Dialog.
    return ScaffoldMessenger(
      key: _messengerKey,
      child: Scaffold(backgroundColor: AppColors.background, body: body),
    );
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

  static const _labels = ['Info', 'Tallas', 'Materiales', 'Resumen'];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (var i = 0; i < 4; i++) ...[
          _StepCircle(index: i, pasoActual: pasoActual, label: _labels[i]),
          if (i < 3)
            Expanded(
              child: _Connector(pasoActual: pasoActual, indexAfter: i),
            ),
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

    // bg/fg aplican al contenido del CÍRCULO (fondo + foreground interno).
    // labelColor es independiente: el texto debajo del círculo va sobre el
    // fondo blanco del modal, así que no puede usar `fg` (que es brandWhite
    // en estados completed/active y quedaría invisible).
    final Color bg;
    final Color fg;
    final Color labelColor;
    final Widget child;

    if (isCompleted) {
      bg = AppColors.success;
      fg = AppColors.brandWhite;
      labelColor = AppColors.success;
      child = const Icon(Icons.check, size: 16, color: AppColors.brandWhite);
    } else if (isActive) {
      bg = AppColors.primary500;
      fg = AppColors.brandWhite;
      labelColor = AppColors.primary500;
      child = Text(
        '${index + 1}',
        style: AppTypography.small.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      );
    } else {
      bg = AppColors.neutral100;
      fg = AppColors.textMuted;
      labelColor = AppColors.textMuted;
      child = Text(
        '${index + 1}',
        style: AppTypography.small.copyWith(
          color: fg,
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
            color: labelColor,
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
    required this.onGuardar,
    required this.guardando,
  });

  final int pasoActual;
  final VoidCallback onCancelar;
  final VoidCallback onAtras;
  final VoidCallback onSiguiente;
  final Future<void> Function() onGuardar;
  final bool guardando;

  @override
  Widget build(BuildContext context) {
    final esUltimo = pasoActual == 3;

    // En pantallas chicas (< 380 px), los 3 botones con texto no entran
    // y "Siguiente" / "Guardar" quedan cortados. Colapsamos a íconos para
    // Atrás/Siguiente y abreviamos Guardar a "OK".
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 380;
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              TextButton(
                onPressed: guardando ? null : onCancelar,
                child: const Text('Cancelar'),
              ),
              const Spacer(),
              if (pasoActual > 0) ...[
                if (compact)
                  IconButton(
                    onPressed: guardando ? null : onAtras,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    tooltip: 'Atrás',
                  )
                else
                  OutlinedButton.icon(
                    onPressed: guardando ? null : onAtras,
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Atrás'),
                  ),
                const SizedBox(width: AppSpacing.sm),
              ],
              if (!esUltimo)
                compact
                    ? IconButton.filled(
                        onPressed: onSiguiente,
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        tooltip: 'Siguiente',
                      )
                    : FilledButton.icon(
                        onPressed: onSiguiente,
                        icon: const Icon(Icons.arrow_forward, size: 16),
                        label: const Text('Siguiente'),
                      )
              else
                FilledButton(
                  onPressed: guardando ? null : onGuardar,
                  child: guardando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.brandWhite,
                          ),
                        )
                      : Text(compact ? 'OK' : 'Guardar'),
                ),
            ],
          ),
        );
      },
    );
  }
}
