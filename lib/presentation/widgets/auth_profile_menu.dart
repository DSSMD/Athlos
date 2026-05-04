// lib/presentation/widgets/auth_profile_menu.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../pages/perfil/mi_perfil_page.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'logout_confirmation_dialog.dart';
import 'user_avatar.dart';

class AuthProfileMenu extends ConsumerWidget {
  final bool isCollapsed;
  final bool showFullInfo;

  const AuthProfileMenu({
    super.key,
    this.isCollapsed = false,
    this.showFullInfo = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);

    // Mobile: avatar compacto que abre el bottom sheet
    if (!showFullInfo) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: InkWell(
          onTap: () => showAuthProfileSheet(context, ref),
          borderRadius: BorderRadius.circular(AppRadius.full),
          hoverColor: Colors.white10,
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: userProfileAsync.when(
              data: (profile) {
                final nombre = profile?['nombre'] ?? 'Usuario';
                return UserAvatar(
                  name: nombre,
                  size: 32,
                  showPresence: true,
                  isOnline: true,
                );
              },
              loading: () => const UserAvatar(name: '?', size: 32),
              error: (_, __) =>
                  const Icon(Icons.error, color: Colors.red, size: 32),
            ),
          ),
        ),
      );
    }

    // Desktop: PopupMenuButton anclado al avatar
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: userProfileAsync.when(
        data: (profile) {
          final nombre = profile?['nombre'] ?? 'Usuario';
          final rolTexto = profile?['roles']?['nombre_rol'] ?? 'Sin Rol';

          return PopupMenuButton<_ProfileAction>(
            tooltip: '',
            position: PopupMenuPosition.over,
            offset: const Offset(0, -4),
            color: AppColors.background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            onSelected: (action) {
              switch (action) {
                case _ProfileAction.profile:
                  _goToProfile(context);
                  break;
                case _ProfileAction.logout:
                  _handleLogout(context, ref);
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<_ProfileAction>(
                value: _ProfileAction.profile,
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      'Mi Perfil',
                      style: AppTypography.small.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem<_ProfileAction>(
                value: _ProfileAction.logout,
                child: Row(
                  children: [
                    const Icon(Icons.logout, size: 20, color: AppColors.error),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      'Cerrar Sesión',
                      style: AppTypography.small.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UserAvatar(
                    name: nombre,
                    size: 36,
                    showPresence: true,
                    isOnline: true,
                  ),
                  if (!isCollapsed) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            nombre,
                            style: AppTypography.small.copyWith(
                              color: AppColors.brandWhite,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(rolTexto, style: AppTypography.caption),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_right,
                      color: Colors.white24,
                      size: 16,
                    ),
                  ],
                ],
              ),
            ),
          );
        },
        loading: () => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const UserAvatar(name: '?', size: 36),
            if (!isCollapsed) ...[
              const SizedBox(width: 12),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        error: (error, stack) => const Icon(Icons.error, color: Colors.red),
      ),
    );
  }
}

enum _ProfileAction { profile, logout }

void _goToProfile(BuildContext context) {
  Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const MiPerfilPage()));
}

Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => const LogoutConfirmationDialog(),
  );

  if (confirm == true) {
    await ref.read(authServiceProvider).signOut();
  }
}

/// Abre un bottom sheet con el menú de perfil (Mi Perfil / Cerrar Sesión).
/// Diseñado para uso en mobile, desde el avatar del header.
Future<void> showAuthProfileSheet(BuildContext context, WidgetRef ref) async {
  final profileAsync = ref.read(userProfileProvider);
  final nombre = profileAsync.value?['nombre'] ?? 'Usuario';
  final rolTexto = profileAsync.value?['roles']?['nombre_rol'] ?? 'Sin Rol';

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grab handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral200,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            // Header con avatar + nombre + rol
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  UserAvatar(name: nombre, size: 48),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          nombre,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          rolTexto,
                          style: AppTypography.caption,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            ListTile(
              leading: const Icon(
                Icons.person_outline,
                color: AppColors.textPrimary,
              ),
              title: Text(
                'Mi Perfil',
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _goToProfile(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.error),
              title: Text(
                'Cerrar Sesión',
                style: AppTypography.body.copyWith(color: AppColors.error),
              ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _handleLogout(context, ref);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      );
    },
  );
}
