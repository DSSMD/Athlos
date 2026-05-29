// lib/presentation/pages/perfil/mi_perfil_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/usuario_model.dart';
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
              error: (_, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl2),
                  child: Text(
                    'No se pudo cargar el perfil',
                    style: AppTypography.body,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (profileData) {
                if (profileData == null) {
                  return Center(
                    child: Text(
                      'No se encontró información del perfil',
                      style: AppTypography.body,
                    ),
                  );
                }

                final usuario = UsuarioModel.fromJson(profileData);

                return _ProfileBody(profile: usuario);
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

  final UsuarioModel profile;

  @override
  Widget build(BuildContext context) {
    final ultimoAccesoStr = profile.lastAccess != null
        ? '${profile.lastAccess!.day.toString().padLeft(2, '0')}/${profile.lastAccess!.month.toString().padLeft(2, '0')}/${profile.lastAccess!.year} ${profile.lastAccess!.hour.toString().padLeft(2, '0')}:${profile.lastAccess!.minute.toString().padLeft(2, '0')}'
        : 'Sin registro';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xl),
          Center(child: UserAvatar(name: profile.name, size: 80)),
          const SizedBox(height: AppSpacing.lg),
          Text(
            profile.name,
            style: AppTypography.h2.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Center(child: _RoleChip(rol: profile.role.name.toUpperCase())),

          // ════════════════════════════════════════════════════════════
          // BOTONES DE ACCIÓN (Editar y Cambiar Contraseña)
          // ════════════════════════════════════════════════════════════
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showEditProfileSheet(context, profile),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Editar Datos'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary500,
                  side: const BorderSide(color: AppColors.primary500),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // AppRadius.md
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implementar flujo de cambio de contraseña
                },
                icon: const Icon(Icons.lock_outline, size: 18),
                label: const Text('Seguridad'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textMuted,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl2),

          _SectionCard(
            title: 'Información personal',
            children: [
              _InfoRow(
                icon: Icons.email_outlined,
                label: 'Email',
                value: profile.email,
              ),
              const Divider(height: 1, color: AppColors.border),
              _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Teléfono',
                value: profile.phone ?? 'No registrado',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          if (profile.isTrabajador) ...[
            _SectionCard(
              title: 'Información laboral',
              children: [
                _InfoRow(
                  icon: Icons.factory_outlined,
                  label: 'Área de Producción',
                  value: profile.nombreArea ?? 'Área no asignada',
                ),
                const Divider(height: 1, color: AppColors.border),
                _InfoRow(
                  icon: Icons.payments_outlined,
                  label: 'Tarifa Base',
                  value: profile.tarifaPagoBase != null
                      ? 'Bs. ${profile.tarifaPagoBase!.toStringAsFixed(2)}'
                      : 'No establecida',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          _SectionCard(
            title: 'Cuenta',
            children: [
              _InfoRow(
                icon: Icons.verified_user_outlined,
                label: 'Estado',
                value: profile.status.name.toUpperCase(),
              ),
              const Divider(height: 1, color: AppColors.border),
              _InfoRow(
                icon: Icons.access_time,
                label: 'Último acceso',
                value: ultimoAccesoStr,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// MODAL DE EDICIÓN (Bottom Sheet)
// ══════════════════════════════════════════════════════════════════════════
void _showEditProfileSheet(BuildContext context, UsuarioModel profile) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true, // Para que el teclado no lo tape
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(24),
      ), // AppRadius.xl
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: _EditProfileForm(profile: profile),
      );
    },
  );
}

class _EditProfileForm extends ConsumerStatefulWidget {
  final UsuarioModel profile;
  const _EditProfileForm({required this.profile});

  @override
  ConsumerState<_EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends ConsumerState<_EditProfileForm> {
  late TextEditingController _phoneCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-llenamos con los datos actuales
    _phoneCtrl = TextEditingController(text: widget.profile.phone ?? '');
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    setState(() => _isLoading = true);

    // TODO: Aquí llamarías a tu AuthProvider o UsuarioService
    // para hacer el UPDATE en la tabla 'profiles' de Supabase.
    // Ejemplo: await ref.read(usuarioServiceProvider).actualizarPerfilPropio(...);

    await Future.delayed(const Duration(seconds: 1)); // Simulación

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.of(context).pop(); // Cierra el modal
      // Mostrar un SnackBar de éxito aquí
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Grab handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.neutral400,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text(
              'Editar Datos Personales',
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Actualiza tu información de contacto. Tu nombre y datos laborales están administrados por RRHH.',
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Campo Teléfono
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Número de Teléfono',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl2),

            // Botón Guardar
            ElevatedButton(
              onPressed: _isLoading ? null : _guardarCambios,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: AppColors.brandWhite,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Guardar Cambios'),
            ),
          ],
        ),
      ),
    );
  }
}

// ... (Las clases _RoleChip, _SectionCard e _InfoRow se mantienen exactamente igual)

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
        borderRadius: BorderRadius.circular(20), // Asumiendo AppRadius.full
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
        borderRadius: BorderRadius.circular(12), // Asumiendo AppRadius.lg
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
