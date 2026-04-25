// ============================================================================
// cliente_identification_card.dart
// Ubicación: lib/presentation/components/clientes/cliente_identification_card.dart
// Descripción: Card "Datos de identificación" — NIT/CI, tipo, razón social,
// representante legal.
// ============================================================================

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/custom_text_field.dart';
import '_section_card.dart';
import '../../../domain/models/cliente_model.dart';

class ClienteIdentificationCard extends StatelessWidget {
  const ClienteIdentificationCard({
    super.key,
    required this.nitCiController,
    required this.razonSocialController,
    required this.representanteController,
    required this.tipoCliente,
    required this.onTipoChanged,
    this.showBadgeActualizado = false,
  });

  final TextEditingController nitCiController;
  final TextEditingController razonSocialController;
  final TextEditingController representanteController;
  final TipoCliente tipoCliente;
  final ValueChanged<TipoCliente> onTipoChanged;
  final bool showBadgeActualizado;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Datos de identificación',
      showBadgeActualizado: showBadgeActualizado,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila 1: NIT/CI + Tipo de cliente
          _Row2(
            left: CustomTextField(
              controller: nitCiController,
              label: 'NIT / CI',
              isOptional: true,
              hint: 'Ej: 1234567',
            ),
            right: _TipoClienteDropdown(
              value: tipoCliente,
              onChanged: onTipoChanged,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Fila 2: Razón social + Representante legal
          _Row2(
            left: CustomTextField(
              controller: razonSocialController,
              label: 'Razón social / Nombre',
              isOptional: true,
              hint: 'Ej: Empresa S.A.',
            ),
            right: CustomTextField(
              controller: representanteController,
              label: 'Representante legal',
              isRequired: true,
              hint: 'Ej: Juan Pérez',
            ),
          ),
        ],
      ),
    );
  }
}

class _TipoClienteDropdown extends StatelessWidget {
  const _TipoClienteDropdown({required this.value, required this.onChanged});

  final TipoCliente value;
  final ValueChanged<TipoCliente> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de cliente',
          style: AppTypography.small.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          decoration: BoxDecoration(
            color: AppColors.brandWhite,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<TipoCliente>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMuted,
              ),
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
              items: TipoCliente.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Text(t.label),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Helper: renderiza 2 widgets en fila en desktop, apilados en mobile.
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
