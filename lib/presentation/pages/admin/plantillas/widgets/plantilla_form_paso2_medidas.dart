// ============================================================================
// lib/presentation/pages/admin/plantillas/widgets/plantilla_form_paso2_medidas.dart
// ============================================================================
// PLACEHOLDER del Paso 2 del form multi-paso de Plantillas.
//
// TODO(plantillas-modulo): implementar en Bloque 6.
// Va a contener:
// - Selector de tallas (chips multi-select de TallaPrenda)
// - Tabla dinámica con tallas como columnas y MedidaPunto como filas
// - Botón "+ Agregar punto de medida"
// - Inicializar con sugerencias de medidas según tipoPrenda
//   usando plantillaService.obtenerMedidasSugeridas()
// ============================================================================

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';

class PlantillaFormPaso2Medidas extends StatelessWidget {
  const PlantillaFormPaso2Medidas({super.key});

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
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: const Icon(
                Icons.straighten,
                size: 40,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              '🚧 Paso 2: Cuadro de Medidas',
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
            const _Bullet('Seleccionar tallas (S, M, L, XL, XXL, 2, 4, 6)'),
            const _Bullet('Definir medidas con valores por talla en centímetros'),
            const _Bullet(
              'Agregar/eliminar puntos de medida según tipo de prenda',
            ),
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
