// ============================================================================
// orden_resumen_card.dart
// Ubicación: lib/presentation/components/ordenes/orden_resumen_card.dart
// Descripción: Card "Resumen" de la columna lateral (SCRUM-75).
// Muestra moneda, listado de productos con subtotales, subtotal general,
// descuento (5% mockeado), total, y equivalente en Bs si moneda es USD.
//
// El descuento del 5% es mock fijo del Figma. Cuando exista lógica de
// descuentos por cliente o promociones, se calcula dinámico.
// TODO(SCRUM-75): conectar a `cliente_provider` para descuentos reales.
// ============================================================================

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import 'orden_draft.dart';

class OrdenResumenCard extends StatelessWidget {
  final OrdenDraft draft;
  final double descuentoFijo; // NUEVO parámetro

  const OrdenResumenCard({
    super.key,
    required this.draft,
    this.descuentoFijo = 0.05,
  });

  // Mock fijo del Figma. Cuando se conecte cliente_provider, leer del
  // perfil del cliente o reglas de promoción.
  static const double _porcentajeDescuento = 0.05;

  @override
  Widget build(BuildContext context) {
    final subtotal = draft.subtotal;

    final descuento = subtotal * descuentoFijo;
    final total = subtotal - descuento;
    final equivalenteBs = draft.moneda == OrdenMoneda.dolares
        ? total * 9.2
        : null;

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
          _header(),
          const SizedBox(height: AppSpacing.lg),
          _filaMoneda(),
          const SizedBox(height: AppSpacing.md),
          if (draft.productos.isEmpty)
            _empty()
          else ...[
            ...draft.productos.map((p) => _filaProducto(p)),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppSpacing.md),
            _filaTotal('Subtotal', draft.formatPrecio(subtotal)),
            const SizedBox(height: AppSpacing.sm),
            _filaDescuento(descuento),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppSpacing.md),
            _filaTotal('Total', draft.formatPrecio(total), destacado: true),
            if (equivalenteBs != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _filaEquivalenteBs(equivalenteBs),
            ],
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _header() {
    return Text('Resumen', style: AppTypography.h3);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILA MONEDA — label + badge con la moneda actual
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _filaMoneda() {
    final esUsd = draft.moneda == OrdenMoneda.dolares;
    return Row(
      children: [
        Text(
          'Moneda:',
          style: AppTypography.small.copyWith(color: AppColors.textMuted),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary500,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            esUsd ? 'USD \$' : 'Bs',
            style: AppTypography.small.copyWith(
              color: AppColors.brandWhite,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Text(
        'Agregá productos para ver el resumen',
        style: AppTypography.small.copyWith(color: AppColors.textMuted),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILA DE PRODUCTO — nombre (cantidad) — precio
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _filaProducto(OrdenProductoItem p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${p.nombre} (${p.cantidad})',
              style: AppTypography.small,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            draft.formatPrecio(p.subtotal),
            style: AppTypography.small.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILA TOTAL/SUBTOTAL — label + valor
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _filaTotal(String label, String valor, {bool destacado = false}) {
    final style = destacado
        ? AppTypography.h3.copyWith(fontWeight: FontWeight.w700)
        : AppTypography.body.copyWith(fontWeight: FontWeight.w600);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: destacado
                ? AppTypography.body.copyWith(fontWeight: FontWeight.w700)
                : AppTypography.small,
          ),
        ),
        Text(valor, style: style),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILA DESCUENTO — verde, con porcentaje
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _filaDescuento(double descuento) {
    final porcentaje = (_porcentajeDescuento * 100).toStringAsFixed(0);
    return Row(
      children: [
        Expanded(
          child: Text('Descuento ($porcentaje%)', style: AppTypography.small),
        ),
        Text(
          '-${draft.formatPrecio(descuento)}',
          style: AppTypography.small.copyWith(
            color: AppColors.success,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILA EQUIVALENTE EN Bs — solo aparece en USD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _filaEquivalenteBs(double valor) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Equivalente en Bs',
            style: AppTypography.small.copyWith(color: AppColors.textMuted),
          ),
        ),
        Text(
          'Bs ${valor.toStringAsFixed(2)}',
          style: AppTypography.small.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}
