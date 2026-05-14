// ============================================================================
// orden_pago_prioridad_card.dart
// Ubicación: lib/presentation/components/ordenes/orden_pago_prioridad_card.dart
// Descripción: Card compacta del sidebar que combina Prioridad + Anticipo
// en un layout denso (SegmentedButton horizontal para prioridad, Row para
// anticipo + método de pago). Reemplaza el uso por separado de
// OrdenPrioridadCard y OrdenAnticipoCard.
//
// Diseñada para que el sidebar entero (Resumen + PagoPrioridad + Calendario)
// quepa arriba de la fold sin scroll en pantallas típicas.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import 'orden_draft.dart';

class OrdenPagoPrioridadCard extends StatefulWidget {
  final OrdenDraft draft;
  final ValueChanged<OrdenDraft> onChanged;

  const OrdenPagoPrioridadCard({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  @override
  State<OrdenPagoPrioridadCard> createState() => _OrdenPagoPrioridadCardState();
}

class _OrdenPagoPrioridadCardState extends State<OrdenPagoPrioridadCard> {
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
    final monedaPrefix = esUsd ? '\$ ' : 'Bs ';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Pago y prioridad', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.md),

          // ─── PRIORIDAD ───
          _label('Prioridad'),
          const SizedBox(height: AppSpacing.xs),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<OrdenPrioridad>(
              segments: const [
                ButtonSegment(
                  value: OrdenPrioridad.normal,
                  label: Text('Normal'),
                ),
                ButtonSegment(value: OrdenPrioridad.alta, label: Text('Alta')),
                ButtonSegment(
                  value: OrdenPrioridad.urgente,
                  label: Text('Urgente'),
                ),
              ],
              selected: {widget.draft.prioridad},
              onSelectionChanged: (Set<OrdenPrioridad> selected) {
                widget.onChanged(
                  widget.draft.copyWith(prioridad: selected.first),
                );
              },
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // ─── ANTICIPO ───
          _label('Anticipo'),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _montoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                      RegExp(r'^\d*\.?\d{0,2}'),
                    ),
                  ],
                  onChanged: (v) {
                    final n = double.tryParse(v) ?? 0;
                    widget.onChanged(widget.draft.copyWith(anticipo: n));
                  },
                  style: AppTypography.small,
                  decoration: InputDecoration(
                    prefixText: monedaPrefix,
                    prefixStyle: AppTypography.small.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                    hintText: '0.00',
                    hintStyle: AppTypography.small.copyWith(
                      color: AppColors.textMuted,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
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
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 3,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: widget.draft.metodoPago,
                      isExpanded: true,
                      style: AppTypography.small,
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
                          widget.onChanged(
                            widget.draft.copyWith(metodoPago: v),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: AppTypography.small.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w500,
    ),
  );
}
