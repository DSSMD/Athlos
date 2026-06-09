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
  void didUpdateWidget(covariant OrdenAnticipoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el anticipo cambia desde afuera (o se resetea), actualizamos el controller
    if (widget.draft.anticipo != oldWidget.draft.anticipo) {
      if (_montoCtrl.text != widget.draft.anticipo.toStringAsFixed(2)) {
        _montoCtrl.text = widget.draft.anticipo == 0
            ? ''
            : widget.draft.anticipo.toStringAsFixed(2);
      }
    }
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    super.dispose();
  }

  // Lógica Financiera
  double get _totalOrden {
    // Asumimos que draft.descuento existe. Si no, usa 0 por ahora.
    final descuento = widget.draft.descuento;
    return widget.draft.subtotalItems - descuento;
  }

  double get _saldoPendiente {
    final saldo = _totalOrden - widget.draft.anticipo;
    return saldo < 0 ? 0 : saldo; // Evitar saldos negativos si dan más anticipo
  }

  void _sugerirMitad() {
    final mitad = _totalOrden / 2;
    widget.onChanged(widget.draft.copyWith(anticipo: mitad));
  }

  @override
  Widget build(BuildContext context) {
    final esUsd = widget.draft.moneda == OrdenMoneda.dolares;
    final prefijo = esUsd ? 'USD \$' : 'Bs.';

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Anticipo y Pagos', style: AppTypography.h3),
              // Botón de acceso rápido para calcular el 50%
              TextButton.icon(
                onPressed: _totalOrden > 0 ? _sugerirMitad : null,
                icon: const Icon(Icons.calculate, size: 16),
                label: const Text('Sugerir 50%'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          _label('Monto de anticipo'),
          const SizedBox(height: AppSpacing.xs),
          _filaMonto(esUsd),

          const SizedBox(height: AppSpacing.lg),
          _label('Método de pago'),
          const SizedBox(height: AppSpacing.xs),
          _dropdownMetodoPago(),

          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          const SizedBox(height: AppSpacing.md),

          // Indicador visual del Saldo Pendiente
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: _saldoPendiente == 0
                  // ignore: deprecated_member_use
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.neutral50,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _saldoPendiente == 0
                      ? 'Pagado en su totalidad'
                      : 'Saldo Pendiente (Contra entrega)',
                  style: AppTypography.small.copyWith(
                    color: _saldoPendiente == 0
                        ? AppColors.success
                        : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$prefijo ${_saldoPendiente.toStringAsFixed(2)}',
                  style: AppTypography.h3.copyWith(
                    color: _saldoPendiente == 0
                        ? AppColors.success
                        : AppColors.primary500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filaMonto(bool esUsd) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
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
              contentPadding: const EdgeInsets.all(AppSpacing.md),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
      ],
    );
  }

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

  Widget _label(String text) => Text(
    text,
    style: AppTypography.small.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w500,
    ),
  );
}
