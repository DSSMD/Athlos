// ============================================================================
// cliente_credit_card.dart
// Ubicación: lib/presentation/components/clientes/cliente_credit_card.dart
// Descripción: Card "Órdenes a crédito" — toggle, límite, días, nota y
// campo de observaciones.
// ============================================================================

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/custom_text_field.dart';
import '_section_card.dart';

class ClienteCreditCard extends StatelessWidget {
  const ClienteCreditCard({
    super.key,
    required this.permiteCredito,
    required this.onPermiteCreditoChanged,
    required this.limiteController,
    required this.diasController,
    required this.notasController,
    this.showBadgeActualizado = false,
  });

  final bool permiteCredito;
  final ValueChanged<bool> onPermiteCreditoChanged;
  final TextEditingController limiteController;
  final TextEditingController diasController;
  final TextEditingController notasController;
  final bool showBadgeActualizado;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Órdenes a crédito',
      showBadgeActualizado: showBadgeActualizado,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Toggle con descripción
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Permitir órdenes a crédito',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'El cliente puede recibir pedidos sin pagar por adelantado',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: permiteCredito,
                onChanged: onPermiteCreditoChanged,
                activeThumbColor: AppColors.brandWhite,
                activeTrackColor: AppColors.primary500,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Límite + Días
          _Row2(
            left: CustomTextField(
              controller: limiteController,
              label: 'Límite de crédito',
              keyboardType: TextInputType.number,
              enabled: permiteCredito,
              hint: '\$0.00',
            ),
            right: CustomTextField(
              controller: diasController,
              label: 'Días de plazo para pago',
              keyboardType: TextInputType.number,
              enabled: permiteCredito,
              hint: '30',
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Nota amarilla
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textPrimary,
                      ),
                      children: const [
                        TextSpan(
                          text: 'Nota: ',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        TextSpan(
                          text:
                              'Si el crédito está desactivado, el sistema requerirá pago completo o anticipo antes de iniciar producción.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Notas / observaciones
          Text(
            'Notas / observaciones',
            style: AppTypography.small.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: notasController,
            maxLines: 3,
            style: AppTypography.body.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Notas internas sobre el cliente...',
              hintStyle: AppTypography.body.copyWith(
                color: AppColors.textMuted,
              ),
              filled: true,
              fillColor: AppColors.brandWhite,
              contentPadding: const EdgeInsets.all(AppSpacing.md),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(
                  color: AppColors.borderFocus,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
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
