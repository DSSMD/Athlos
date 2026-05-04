// lib/presentation/pages/perfil/mi_perfil_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/shared/mobile_screen_header.dart';
import '../../widgets/user_avatar.dart';

class MiPerfilPage extends ConsumerWidget {
  const MiPerfilPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          const MobileScreenHeader(
            title: 'Mi Perfil',
            showBackButton: true,
            showAvatar: false,
          ),
          Expanded(
            child: profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl2),
                  child: Text(
                    'No se pudo cargar el perfil',
                    style: AppTypography.body,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (profile) {
                if (profile == null) {
                  return Center(
                    child: Text(
                      'No se pudo cargar el perfil',
                      style: AppTypography.body,
                    ),
                  );
                }
                return _ProfileBody(profile: profile);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.profile});

  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final nombre = (profile['nombre'] ?? 'Usuario') as String;
    final rol = (profile['roles']?['nombre_rol'] ?? 'Sin Rol') as String;
    // TODO: backend aún no expone email/teléfono/último acceso en el perfil.
    final email = profile['email'] as String?;
    final telefono = profile['telefono'] as String?;
    final ultimoAcceso = profile['ultimo_acceso'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Center(child: UserAvatar(name: nombre, size: 80)),
          const SizedBox(height: AppSpacing.lg),
          Text(
            nombre,
            style: AppTypography.h2.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(child: _RoleChip(rol: rol)),
          const SizedBox(height: AppSpacing.xl2),
          _SectionCard(
            title: 'Información personal',
            children: [
              _InfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: email ?? '—',
              ),
              const Divider(height: 1, color: AppColors.border),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Teléfono',
                value: telefono ?? '—',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _SectionCard(
            title: 'Cuenta',
            children: [
              _InfoRow(icon: Icons.badge_outlined, label: 'Rol', value: rol),
              const Divider(height: 1, color: AppColors.border),
              _InfoRow(
                icon: Icons.access_time,
                label: 'Último acceso',
                value: ultimoAcceso ?? 'Sin registro',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.rol});
  final String rol;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary500.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        rol,
        style: AppTypography.small.copyWith(
          color: AppColors.primary500,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              title,
              style: AppTypography.small.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: AppTypography.caption),
                const SizedBox(height: 2),
                Text(value, style: AppTypography.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
