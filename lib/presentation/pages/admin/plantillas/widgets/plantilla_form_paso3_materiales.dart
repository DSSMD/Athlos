// ============================================================================
// lib/presentation/pages/admin/plantillas/widgets/plantilla_form_paso3_materiales.dart
// ============================================================================
// PLACEHOLDER del Paso 3 del form multi-paso de Plantillas.
//
// TODO(plantillas-modulo): implementar en Bloque 5.
// Va a contener:
// - Lista dinámica de MaterialPlantilla
// - Selector de insumo (dropdown con búsqueda) reutilizando inventarioProvider
// - Campo cantidad por material
// - Display de unidad heredada del insumo (read-only)
// - Botón "+ Agregar material"
// ============================================================================

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';

class PlantillaFormPaso3Materiales extends StatelessWidget {
  const PlantillaFormPaso3Materiales({super.key});

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
                color: AppColors.info.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 40,
                color: AppColors.info,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              '🚧 Paso 3: Receta de Materiales',
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
              'Va a permitir:',
              style: AppTypography.small.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xs),
            const _Bullet('Seleccionar insumos del inventario existente'),
            const _Bullet('Definir cantidad por insumo'),
            const _Bullet('Agregar/eliminar materiales de la receta'),
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
