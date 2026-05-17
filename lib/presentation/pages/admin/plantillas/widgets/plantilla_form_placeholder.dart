// ============================================================================
// lib/presentation/pages/admin/plantillas/widgets/plantilla_form_placeholder.dart
// ============================================================================
// DEPRECATED — reemplazado por PlantillaFormPage en Bloque 3. Se mantiene
// temporalmente como fallback. Eliminar cuando todos los bloques estén
// estables (Bloque 4 cerrado y form multi-paso probado en producción).
//
// Modal placeholder de "Nueva / Editar plantilla". Es una vista DEMO: muestra
// un mensaje de "en construcción" con el título adaptado al modo, mientras
// no exista el form multi-paso real. Sirve para que el PO vea el flujo del
// botón sin bloquear la pantalla principal.
// - Mobile: full-screen route (MaterialPageRoute con fullscreenDialog: true)
// - Desktop: Dialog centrado con maxWidth 460
// - showPlantillaFormPlaceholder(...): helper público con `mode` e
//   `initialPlantilla` (el modo 'editar' requiere initialPlantilla != null).
// ============================================================================
//
// ============================================================================
// TODO(plantillas-modulo): este placeholder debe reemplazarse por el form
// multi-paso real (PlantillaFormPage) que tendrá 4 pasos:
// - Paso 1: Información general (nombre, tipo prenda, especificaciones)
// - Paso 2: Cuadro de medidas (selector tallas + tabla dinámica)
// - Paso 3: Receta de materiales (selector de insumos)
// - Paso 4: Resumen y guardado
// En modo 'editar' debe precargar los datos de initialPlantilla.
// ============================================================================

import 'package:flutter/material.dart';

import '../../../../../domain/models/plantilla_model.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';

// ─── HELPER PÚBLICO ─────────────────────────────────────────────────────────

/// Abre el placeholder. En mobile usa una route fullscreen, en desktop un
/// Dialog centrado. Se considera mobile si el ancho < 600 (consistente con
/// el resto de las modales del proyecto).
///
/// [mode] puede ser `'crear'` (default) o `'editar'`. En modo `'editar'`
/// hay que pasar [initialPlantilla] o lanza AssertionError.
Future<void> showPlantillaFormPlaceholder(
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

  final isMobile = MediaQuery.of(context).size.width < 600;
  if (isMobile) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: _PlaceholderBody(
              showAppBarBack: true,
              mode: mode,
              initialPlantilla: initialPlantilla,
            ),
          ),
        ),
      ),
    );
  }
  return showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: _PlaceholderBody(
          showAppBarBack: false,
          mode: mode,
          initialPlantilla: initialPlantilla,
        ),
      ),
    ),
  );
}

// ─── BODY ───────────────────────────────────────────────────────────────────

class _PlaceholderBody extends StatelessWidget {
  const _PlaceholderBody({
    required this.showAppBarBack,
    required this.mode,
    required this.initialPlantilla,
  });

  /// En mobile mostramos un botón de cerrar arriba; en desktop el Dialog
  /// se cierra solo con el botón "Cerrar" del final.
  final bool showAppBarBack;
  final String mode;
  final PlantillaModel? initialPlantilla;

  String get _titulo {
    if (mode == 'editar' && initialPlantilla != null) {
      return 'Editar Plantilla: ${initialPlantilla!.nombre}';
    }
    return 'Nueva Plantilla';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showAppBarBack)
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Cerrar',
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary500.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: const Icon(
              Icons.architecture,
              size: 40,
              color: AppColors.primary500,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(_titulo, style: AppTypography.h2, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '🚧 En construcción',
            style: AppTypography.body.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Esta vista estará disponible próximamente. Por ahora solo se '
            'puede ver el listado de plantillas existentes.',
            style: AppTypography.small.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl2),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
