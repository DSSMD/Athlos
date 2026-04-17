// ============================================================================
// status_badge.dart
// Ubicación sugerida: lib/presentation/widgets/status_badge.dart
// Descripción: Indicador de estado con punto de color + etiqueta.
// Variantes: En línea / Activo / Inactivo.
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum UserStatus { enLinea, activo, inactivo }

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final UserStatus status;

  @override
  Widget build(BuildContext context) {
    final config = _configFor(status);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: config.dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          config.label,
          style: AppTypography.small.copyWith(
            color: config.textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  _StatusConfig _configFor(UserStatus status) {
    switch (status) {
      case UserStatus.enLinea:
        return const _StatusConfig(
          label: 'En línea',
          dotColor: AppColors.success,
          textColor: AppColors.success,
        );
      case UserStatus.activo:
        return const _StatusConfig(
          label: 'Activo',
          dotColor: AppColors.success,
          textColor: AppColors.success,
        );
      case UserStatus.inactivo:
        return const _StatusConfig(
          label: 'Inactivo',
          dotColor: AppColors.neutral400,
          textColor: AppColors.neutral500,
        );
    }
  }
}

class _StatusConfig {
  const _StatusConfig({
    required this.label,
    required this.dotColor,
    required this.textColor,
  });
  final String label;
  final Color dotColor;
  final Color textColor;
}