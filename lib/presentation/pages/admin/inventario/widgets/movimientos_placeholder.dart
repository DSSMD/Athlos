// lib/presentation/pages/admin/inventario/widgets/movimientos_placeholder.dart

import 'package:flutter/material.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';

class MovimientosPlaceholder extends StatelessWidget {
  const MovimientosPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl3),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.swap_horiz, size: 80, color: AppColors.textMuted),
            const SizedBox(height: AppSpacing.lg),
            Text('Movimientos', style: AppTypography.h3),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Esta sección está en desarrollo',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
