// ============================================================================
// cliente_contact_card.dart
// Ubicación: lib/presentation/components/clientes/cliente_contact_card.dart
// Descripción: Card "Información de contacto" — teléfono (con botón WhatsApp),
// teléfono secundario, email, dirección.
// ============================================================================

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/custom_text_field.dart';
import '_section_card.dart';

class ClienteContactCard extends StatelessWidget {
  const ClienteContactCard({
    super.key,
    required this.telefonoController,
    required this.telefonoSecController,
    required this.emailController,
    required this.direccionController,
    required this.onWhatsappTap,
    this.showBadgeActualizado = false,
  });

  final TextEditingController telefonoController;
  final TextEditingController telefonoSecController;
  final TextEditingController emailController;
  final TextEditingController direccionController;
  final VoidCallback onWhatsappTap;
  final bool showBadgeActualizado;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return SectionCard(
      title: 'Información de contacto',
      showBadgeActualizado: showBadgeActualizado,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila 1: Teléfono + botón WhatsApp + Teléfono secundario
          _PhoneRow(
            telefonoController: telefonoController,
            telefonoSecController: telefonoSecController,
            onWhatsappTap: onWhatsappTap,
            isMobile: isMobile,
          ),
          const SizedBox(height: AppSpacing.sm),
          // Mensaje debajo del teléfono
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.xs),
            child: Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 14,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Al hacer clic se abre chat de WhatsApp con este número',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Fila 2: Email + Dirección
          _Row2(
            left: CustomTextField(
              controller: emailController,
              label: 'Email',
              isOptional: true,
              keyboardType: TextInputType.emailAddress,
            ),
            right: CustomTextField(
              controller: direccionController,
              label: 'Dirección',
              isOptional: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhoneRow extends StatelessWidget {
  const _PhoneRow({
    required this.telefonoController,
    required this.telefonoSecController,
    required this.onWhatsappTap,
    required this.isMobile,
  });

  final TextEditingController telefonoController;
  final TextEditingController telefonoSecController;
  final VoidCallback onWhatsappTap;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    // Teléfono principal + botón WhatsApp (siempre juntos)
    final telefonoConBtn = Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: CustomTextField(
            controller: telefonoController,
            label: 'Teléfono / WhatsApp',
            isRequired: true,
            keyboardType: TextInputType.phone,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _WhatsappButton(onTap: onWhatsappTap),
        ),
      ],
    );

    final telefonoSec = CustomTextField(
      controller: telefonoSecController,
      label: 'Teléfono secundario',
      isOptional: true,
      hint: 'Opcional...',
      keyboardType: TextInputType.phone,
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          telefonoConBtn,
          const SizedBox(height: AppSpacing.lg),
          telefonoSec,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: telefonoConBtn),
        const SizedBox(width: AppSpacing.lg),
        Expanded(child: telefonoSec),
      ],
    );
  }
}

class _WhatsappButton extends StatelessWidget {
  const _WhatsappButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat, color: AppColors.brandWhite, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'WhatsApp',
              style: AppTypography.small.copyWith(
                color: AppColors.brandWhite,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row2 extends StatelessWidget {
  const _Row2({required this.left, required this.right});
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          left,
          const SizedBox(height: AppSpacing.lg),
          right,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: AppSpacing.lg),
        Expanded(child: right),
      ],
    );
  }
}
