// ============================================================================
// role_badge.dart
// Ubicación sugerida: lib/presentation/widgets/role_badge.dart
// Descripción: Píldora de rol con 4 variantes de color (Super Admin,
// Administrador, Producción, Ventas). Widget atómico sin lógica de negocio.
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum UserRole { superAdmin, administrador, produccion, ventas }

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
        borderRadius: BorderRadius.circular(AppRadius.full),
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
      case UserRole.superAdmin:
        return const _RoleConfig(
          label: 'Super Admin',
          bg: AppColors.neutral950,
          fg: AppColors.brandWhite,
        );
      case UserRole.administrador:
        return const _RoleConfig(
          label: 'Administrador',
          bg: AppColors.infoBg,
          fg: AppColors.info,
        );
      case UserRole.produccion:
        return const _RoleConfig(
          label: 'Producción',
          bg: AppColors.warningBg,
          fg: Color(0xFFA16207), // amarillo oscuro para legibilidad
        );
      case UserRole.ventas:
        return const _RoleConfig(
          label: 'Ventas',
          bg: Color(0xFFF3E8FF), // violeta claro
          fg: Color(0xFF7C3AED), // violeta
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