// ============================================================================
// role_dropdown.dart
// ============================================================================

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../../domain/models/usuario_model.dart';
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
              TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.error),
              ),
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
          decoration: InputDecoration(
            hintText: 'Seleccionar rol',
            hintStyle: AppTypography.small.copyWith(color: AppColors.textMuted),
          ),
          items: UserRole.values
              .map(
                (role) => DropdownMenuItem(
                  value: role,
                  child: Row(
                    children: [
                      RoleBadge(role: role),
                      const SizedBox(width: AppSpacing.sm),
                      Text(_descriptionFor(role), style: AppTypography.caption),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  // 2. ACTUALIZAMOS LAS DESCRIPCIONES A LOS ROLES REALES
  String _descriptionFor(UserRole role) {
    switch (role) {
      case UserRole.administrador:
        return 'Acceso total y gestión'; // Ahora este es el rango máximo
      case UserRole.produccion:
        return 'Lotes y tareas';
      case UserRole.cajas:
        return 'Transacciones y cierre de caja';
      case UserRole.invitado:
        return 'Consulta y lectura'; // El nuevo rol de tu base de datos
    }
  }
}
