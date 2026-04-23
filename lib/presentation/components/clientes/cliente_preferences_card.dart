// ============================================================================
// cliente_preferences_card.dart
// Ubicación: lib/presentation/components/clientes/cliente_preferences_card.dart
// Descripción: Card "Preferencias" — toggles para cliente prioritario y
// facturación electrónica.
// ============================================================================

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '_section_card.dart';

class ClientePreferencesCard extends StatelessWidget {
  const ClientePreferencesCard({
    super.key,
    required this.clientePrioritario,
    required this.onPrioritarioChanged,
    required this.facturacionElectronica,
    required this.onFacturacionChanged,
    this.showBadgeActualizado = false,
  });

  final bool clientePrioritario;
  final ValueChanged<bool> onPrioritarioChanged;
  final bool facturacionElectronica;
  final ValueChanged<bool> onFacturacionChanged;
  final bool showBadgeActualizado;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Preferencias',
      showBadgeActualizado: showBadgeActualizado,
      child: Column(
        children: [
          _ToggleRow(
            title: 'Cliente prioritario',
            subtitle: 'Prioridad en producción y descuentos especiales',
            value: clientePrioritario,
            onChanged: onPrioritarioChanged,
          ),
          const SizedBox(height: AppSpacing.lg),
          _ToggleRow(
            title: 'Facturación electrónica',
            subtitle: 'Enviar factura automáticamente al email',
            value: facturacionElectronica,
            onChanged: onFacturacionChanged,
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.brandWhite,
          activeTrackColor: AppColors.primary500,
        ),
      ],
    );
  }
}
