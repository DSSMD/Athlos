// ============================================================================
// orden_anticipo_card.dart
// Ubicación: lib/presentation/components/ordenes/orden_anticipo_card.dart
// Descripción: Card "Anticipo" de la columna lateral (SCRUM-75).
// Monto + dropdown método de pago + nota "50% del total como anticipo".
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import 'orden_draft.dart';

class OrdenAnticipoCard extends StatefulWidget {
  final OrdenDraft draft;
  final ValueChanged<OrdenDraft> onChanged;

  const OrdenAnticipoCard({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  @override
  State<OrdenAnticipoCard> createState() => _OrdenAnticipoCardState();
}

class _OrdenAnticipoCardState extends State<OrdenAnticipoCard> {
  late final TextEditingController _montoCtrl;

  static const List<String> _metodosPago = [
    'Transferencia',
    'Efectivo',
    'Cheque',
    'Tarjeta',
  ];

  @override
  void initState() {
    super.initState();
    _montoCtrl = TextEditingController(
      text: widget.draft.anticipo == 0
          ? ''
          : widget.draft.anticipo.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esUsd = widget.draft.moneda == OrdenMoneda.dolares;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Anticipo', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.lg),
          _label('Monto de anticipo'),
          const SizedBox(height: AppSpacing.xs),
          _filaMonto(esUsd),
          const SizedBox(height: AppSpacing.lg),
          _label('Método de pago'),
          const SizedBox(height: AppSpacing.xs),
          _dropdownMetodoPago(),
          const SizedBox(height: AppSpacing.md),
          Text(
            '50% del total como anticipo',
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILA MONTO — prefijo de moneda + input
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _filaMonto(bool esUsd) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            esUsd ? 'USD \$' : 'Bs',
            style: AppTypography.small.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: TextField(
            controller: _montoCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            onChanged: (v) {
              final n = double.tryParse(v) ?? 0;
              widget.onChanged(widget.draft.copyWith(anticipo: n));
            },
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: AppTypography.small.copyWith(
                color: AppColors.textMuted,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
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
                borderSide: const BorderSide(color: AppColors.primary500),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DROPDOWN MÉTODO DE PAGO
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _dropdownMetodoPago() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: widget.draft.metodoPago,
          isExpanded: true,
          items: _metodosPago
              .map(
                (m) => DropdownMenuItem(
                  value: m,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                    child: Text(m),
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) {
              widget.onChanged(widget.draft.copyWith(metodoPago: v));
            }
          },
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: AppTypography.small.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
