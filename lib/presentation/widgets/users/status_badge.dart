// ============================================================================
// status_badge.dart
// Ubicación sugerida: lib/presentation/widgets/status_badge.dart
// ============================================================================

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../../domain/models/usuario_model.dart';

// 2. ELIMINAMOS EL ENUM VIEJO QUE ESTABA AQUÍ

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

  // 3. ACTUALIZAMOS EL SWITCH (Solo Activo e Inactivo)
  _StatusConfig _configFor(UserStatus status) {
    switch (status) {
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
