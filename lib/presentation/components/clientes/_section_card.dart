// ============================================================================
// _section_card.dart
// Ubicación: lib/presentation/components/clientes/_section_card.dart
// Descripción: Card contenedora reutilizable con título y badge opcional.
// El underscore al inicio del nombre indica que es privado a este paquete.
// ============================================================================

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.showBadgeActualizado = false,
  });

  final String title;
  final Widget child;
  final bool showBadgeActualizado;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.brandWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: título + badge opcional
          Row(
            children: [
              Text(
                title,
                style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
              ),
              if (showBadgeActualizado) ...[
                const SizedBox(width: AppSpacing.md),
                const _BadgeActualizado(),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          child,
        ],
      ),
    );
  }
}

class _BadgeActualizado extends StatelessWidget {
  const _BadgeActualizado();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        'Actualizado',
        style: AppTypography.caption.copyWith(
          color: AppColors.info,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
