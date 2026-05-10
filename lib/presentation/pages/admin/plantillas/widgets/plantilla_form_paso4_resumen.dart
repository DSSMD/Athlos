// ============================================================================
// lib/presentation/pages/admin/plantillas/widgets/plantilla_form_paso4_resumen.dart
// ============================================================================
// PLACEHOLDER del Paso 4 del form multi-paso de Plantillas.
//
// TODO(plantillas-modulo): implementar en Bloque 4.
// Va a contener:
// - Sección "Información general" (nombre, tipo, especificaciones)
// - Sección "Tallas seleccionadas" (chips de las tallas elegidas)
// - Sección "Cuadro de medidas" (mini-tabla resumida)
// - Sección "Materiales" (lista compacta con cantidad y unidad)
// - Botón "Guardar" que llama a:
//   - mode='crear': plantillaProvider.notifier.crearPlantilla(...)
//   - mode='editar': plantillaProvider.notifier.actualizarPlantilla(...)
// ============================================================================

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';

class PlantillaFormPaso4Resumen extends StatelessWidget {
  const PlantillaFormPaso4Resumen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl2),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: const Icon(
                Icons.summarize,
                size: 40,
                color: AppColors.success,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              '🚧 Paso 4: Resumen y Guardado',
              style: AppTypography.h3,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Esta sección se implementa en el próximo bloque.',
              style: AppTypography.small.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Va a mostrar:',
              style: AppTypography.small.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xs),
            const _Bullet('Vista compacta de toda la información cargada'),
            const _Bullet('Botón Guardar para crear/actualizar la plantilla'),
            const _Bullet('Confirmación antes de guardar'),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(
            child: Text(
              text,
              style: AppTypography.small.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
