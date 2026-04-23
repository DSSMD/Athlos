// ============================================================================
// user_list_row.dart
// Ubicación sugerida: lib/presentation/components/user_list_row.dart
// Descripción: Fila de la tabla de Usuarios para vista Desktop.
// Muestra: avatar + nombre/email, rol, permisos, estado, último acceso, editar.
// ============================================================================

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import '../../widgets/users/permission_chip.dart';
import '../../widgets/users/role_badge.dart';
import '../../widgets/users/status_badge.dart';

import '../../../domain/models/usuario_model.dart';
import '../../widgets/user_avatar.dart';

class UserListRow extends StatefulWidget {
  const UserListRow({super.key, required this.user, required this.onEdit});

  final UsuarioModel user;
  final VoidCallback onEdit;

  @override
  State<UserListRow> createState() => _UserListRowState();
}

class _UserListRowState extends State<UserListRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        color: _hovered ? AppColors.neutral50 : Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // USUARIO (avatar + nombre + email)
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  UserAvatar(
                    name: u.name,
                    size: 40,
                    showPresence: true,
                    isOnline:
                        false, // Aquí podrías usar u.status para determinarlo en el futuro
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          u.name,
                          style: AppTypography.small.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          u.email,
                          style: AppTypography.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // ROL
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: RoleBadge(role: u.role),
              ),
            ),
            // PERMISOS
            Expanded(
              flex: 3,
              // Dejamos este espacio vacío por ahora para no romper las columnas de la tabla.
              // child: _PermissionsRow(permissions: u.permissions),
              child: _PermissionsRow(permissions: u.permissions),
            ),
            // ESTADO
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: StatusBadge(status: u.status),
              ),
            ),
            // ÚLTIMO ACCESO
            Expanded(
              flex: 2,
              child: Text(
                // Formateo seguro para DateTime? a String
                u.lastAccess != null
                    ? '${u.lastAccess!.day}/${u.lastAccess!.month}/${u.lastAccess!.year}'
                    : 'Nunca',
                style: AppTypography.small.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // EDITAR
            SizedBox(
              width: 80,
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onEdit,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Editar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila de permisos con corte "+N" cuando exceden el espacio disponible.
/// La dejamos comentada/inactiva hasta que tu base de datos maneje permisos por separado.
///

class _PermissionsRow extends StatelessWidget {
  const _PermissionsRow({required this.permissions});
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
