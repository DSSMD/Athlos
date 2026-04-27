// ============================================================================
// user_card.dart
// Ubicación sugerida: lib/presentation/components/user_card.dart
// Descripción: Card de usuario para vista Mobile del listado.
// Layout vertical compacto con avatar + info + permisos + estado.
// ============================================================================

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import '../../widgets/users/permission_chip.dart';
import '../../widgets/users/role_badge.dart';
import '../../widgets/users/status_badge.dart';

import '../../widgets/user_avatar.dart';
import '../../../domain/models/usuario_model.dart';

//import '../../widgets/users/user_avatar.dart';

class UserCard extends StatelessWidget {
  const UserCard({super.key, required this.user, required this.onTap});

  final UsuarioModel user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: avatar + nombre/email + role badge a la derecha
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserAvatar(
                    name: user.name,
                    size: 44,
                    showPresence: true,
                    isOnline:
                        false, // Aquí podrías usar user.status para determinarlo
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.name,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          user.email,
                          style: AppTypography.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  RoleBadge(role: user.role),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Permisos (si tiene)
              // Aquí usamos el getter permissions del modelo para mostrar los permisos correspondientes
              if (user.permissions.isNotEmpty)
                _PermissionsWrap(permissions: user.permissions),
              const SizedBox(height: AppSpacing.md),

              // Footer: estado + último acceso
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  StatusBadge(status: user.status),
                  // Formateamos el DateTime a texto. Si es null, mostramos 'Nunca'
                  Text(
                    user.lastAccess != null
                        ? '${user.lastAccess!.day}/${user.lastAccess!.month}/${user.lastAccess!.year}'
                        : 'Nunca',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionsWrap extends StatelessWidget {
  const _PermissionsWrap({required this.permissions});
  final List<String> permissions;

  @override
  Widget build(BuildContext context) {
    const maxVisible = 3;
    final visible = permissions.take(maxVisible).toList();
    final hidden = permissions.length - visible.length;

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        ...visible.map((p) => PermissionChip(label: p)),
        if (hidden > 0) PermissionChip(label: '+$hidden'),
      ],
    );
  }
}
