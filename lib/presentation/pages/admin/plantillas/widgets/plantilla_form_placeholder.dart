// ============================================================================
// lib/presentation/pages/admin/plantillas/widgets/plantilla_form_placeholder.dart
// ============================================================================
// Modal placeholder para "Nueva plantilla". Es una vista DEMO: muestra un
// mensaje de "en construcción" para que el PO vea el flujo del botón sin que
// haya formulario funcional todavía.
// - Mobile: full-screen route (MaterialPageRoute con fullscreenDialog: true)
// - Desktop: Dialog centrado con maxWidth 460
// - showPlantillaFormPlaceholder(context): helper público para abrirlo
// ============================================================================

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';

// ─── HELPER PÚBLICO ─────────────────────────────────────────────────────────

/// Abre el placeholder. En mobile usa una route fullscreen, en desktop un
/// Dialog centrado. Se considera mobile si el ancho < 600 (consistente con
/// el resto de las modales del proyecto).
Future<void> showPlantillaFormPlaceholder(BuildContext context) {
  final isMobile = MediaQuery.of(context).size.width < 600;
  if (isMobile) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(child: _PlaceholderBody(showAppBarBack: true)),
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
        child: const _PlaceholderBody(showAppBarBack: false),
      ),
    ),
  );
}

// ─── BODY ───────────────────────────────────────────────────────────────────

class _PlaceholderBody extends StatelessWidget {
  const _PlaceholderBody({required this.showAppBarBack});

  /// En mobile mostramos un botón de cerrar arriba; en desktop el Dialog
  /// se cierra solo con el botón "Cerrar" del final.
  final bool showAppBarBack;

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
          Text(
            'Formulario de Plantilla',
            style: AppTypography.h2,
            textAlign: TextAlign.center,
          ),
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
