// ============================================================================
// role_dropdown.dart
// Ubicación sugerida: lib/presentation/widgets/role_dropdown.dart
// Descripción: Dropdown de roles de Athlos con estados hover/focus/disabled
// y preview del RoleBadge en cada opción. Cumple con el punto del checklist
// JIRA "Dropdown de Roles con sus respectivos estados visuales".
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'role_badge.dart';

class RoleDropdown extends StatelessWidget {
  const RoleDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final UserRole? value;
  final ValueChanged<UserRole?>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: AppTypography.small.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            children: const [
              TextSpan(text: 'Rol'),
              TextSpan(text: ' *', style: TextStyle(color: AppColors.error)),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<UserRole>(
          initialValue: value,
          onChanged: enabled ? onChanged : null,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          style: AppTypography.small.copyWith(color: AppColors.textPrimary),
          dropdownColor: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          decoration: InputDecoration(
            hintText: 'Seleccionar rol',
            hintStyle: AppTypography.small.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          items: UserRole.values
              .map((role) => DropdownMenuItem(
                    value: role,
                    child: Row(
                      children: [
                        RoleBadge(role: role),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _descriptionFor(role),
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  String _descriptionFor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Acceso total';
      case UserRole.administrador:
        return 'Gestión y reportes';
      case UserRole.produccion:
        return 'Lotes y tareas';
      case UserRole.ventas:
        return 'Órdenes y clientes';
    }
  }
}