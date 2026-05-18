// ============================================================================
// orden_resumen_card.dart
// Ubicación: lib/presentation/components/ordenes/orden_resumen_card.dart
// Descripción: Card "Resumen" de la columna lateral del form Crear Orden.
// Muestra moneda, listado de ítems con subtotales, subtotal general,
// descuento (5% mockeado del Figma), total y equivalente en Bs si moneda es USD.
//
// Refactor (esquema nuevo):
//   - Lee draft.items (List<OrdenItemDraft>) y draft.subtotalItems en lugar
//     de los campos legacy draft.productos / draft.subtotal.
//   - La fila por ítem muestra nombre + cantidad total (suma de tallas) +
//     subtotal calculado como precioUnitario × cantidadTotal.
//   - El descuento del 5% sigue mock fijo del Figma.
// ============================================================================

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import 'orden_draft.dart';

class OrdenResumenCard extends StatelessWidget {
  final OrdenDraft draft;
  final double descuentoFijo;

  const OrdenResumenCard({
    super.key,
    required this.draft,
    this.descuentoFijo = 0.05,
  });

  static const double _porcentajeDescuento = 0.05;

  // ─── Helpers locales por ítem (duplican lo que tiene OrdenProductosCard;
  //     se pueden promover a getters de OrdenItemDraft en una limpieza
  //     futura para deduplicar) ───
  static int _cantidadTotal(OrdenItemDraft item) =>
      item.tallas.fold(0, (sum, t) => sum + t.cantidad);

  static double _subtotalItem(OrdenItemDraft item) =>
      item.precioUnitario * _cantidadTotal(item);

  @override
  Widget build(BuildContext context) {
    final subtotal = draft.subtotalItems;

    // Aquí usamos el descuento real del draft. Si lo implementas luego, cámbialo a:
    // final descuento = draft.descuento ?? 0.0;
    // Por ahora, lo mantenemos en 0 para que no altere tus números hasta que agregues el input.
    final descuento = 0.0;

    final total = subtotal - descuento;
    final equivalenteBs = draft.moneda == OrdenMoneda.dolares ? total : null;

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

          if (draft.items.isEmpty)
            _empty()
          else ...[
            ...draft.items.map((item) => _filaItem(item)),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppSpacing.md),

            _filaTotal('Subtotal', draft.formatPrecio(subtotal)),

            // Solo mostramos la fila de descuento si es mayor a 0
            if (descuento > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              _filaDescuento(descuento),
            ],

            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppSpacing.md),

            _filaTotal(
              'Total de la Orden',
              draft.formatPrecio(total),
              destacado: true,
            ),

            if (equivalenteBs != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _filaEquivalenteBs(equivalenteBs),
            ],
          ],
        ],
      ),
    );
  }

  Widget _header() => Text('Resumen', style: AppTypography.h3);

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

  Widget _empty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Text(
        'Agregá ítems para ver el resumen',
        style: AppTypography.small.copyWith(color: AppColors.textMuted),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _filaItem(OrdenItemDraft item) {
    final cant = _cantidadTotal(item);
    final sub = _subtotalItem(item);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${item.nombre} ($cant)',
              style: AppTypography.small,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            draft.formatPrecio(sub),
            style: AppTypography.small.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

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
