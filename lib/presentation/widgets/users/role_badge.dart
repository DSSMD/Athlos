// ============================================================================
// role_badge.dart
// ============================================================================

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
// 1. IMPORTAMOS EL MODELO REAL
import '../../../domain/models/usuario_model.dart';

// 2. ENUM UserRole ELIMINADO (Ahora viene del modelo)

class RoleBadge extends StatelessWidget {
  const RoleBadge({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final config = _configFor(role);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: config.bg,
        borderRadius: BorderRadius.circular(AppRadius.full), // Asegúrate de tener AppRadius definido en tu theme
      ),
      child: Text(
        config.label,
        style: AppTypography.caption.copyWith(
          color: config.fg,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  _RoleConfig _configFor(UserRole role) {
    switch (role) {
      case UserRole.administrador:
        return const _RoleConfig(
          label: 'Administrador', // Al ser el mayor rango ahora, le damos el color oscuro
          bg: AppColors.neutral950,
          fg: AppColors.brandWhite,
        );
      case UserRole.produccion:
        return const _RoleConfig(
          label: 'Producción', // Puedes dejarlo corto en la UI aunque en DB sea "Operador..."
          bg: AppColors.warningBg,
          fg: Color(0xFFA16207), 
        );
      case UserRole.cajas:
        return const _RoleConfig(
          label: 'Cajas',
          bg: Color(0xFFD1D5DB), 
          fg: Color(0xFF4B5563), 
        );
      case UserRole.invitado:
        return const _RoleConfig(
          label: 'Invitado',
          bg: AppColors.neutral100, // Un gris sutil para los invitados
          fg: AppColors.textSecondary,
        );
    }
  }
}

class _RoleConfig {
  const _RoleConfig({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;
}