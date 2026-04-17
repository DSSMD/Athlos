// ============================================================================
// kpi_card.dart
// Ubicación sugerida: lib/presentation/widgets/kpi_card.dart
// Descripción: Tarjeta de KPI con número grande + label + descripción opcional.
// Usada en la cabecera del listado de Usuarios (4 cards: Super Admin,
// Administrador, Producción, Ventas).
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.value,
    required this.label,
    this.description,
    this.valueColor,
  });

  final String value;
  final String label;
  final String? description;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTypography.h1.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: AppTypography.small.copyWith(
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          if (description != null) ...[
            const SizedBox(height: 2),
            Text(
              description!,
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}