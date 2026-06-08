// ============================================================================
// ventas_deudores.dart
// Panel de clientes con saldo pendiente para el dashboard de ventas.
// Usa el campo deudaTotal que clientesProvider ya entrega precomputado
// (ClienteService lo calcula client-side a partir de órdenes y pagos).
// NO se hardcodea 0 — a diferencia del placeholder en clientes_page.dart.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../../../../domain/models/cliente_model.dart';

class VentasDeudores extends StatelessWidget {
  const VentasDeudores({
    super.key,
    required this.clientes,
    this.limite = 5,
  });

  final List<ClienteModel> clientes;
  final int limite;

  @override
  Widget build(BuildContext context) {
    final moneda =
        NumberFormat.currency(symbol: 'Bs. ', decimalDigits: 2, locale: 'es_BO');

    final deudores = clientes.where((c) => c.deudaTotal > 0).toList()
      ..sort((a, b) => b.deudaTotal.compareTo(a.deudaTotal));
    final visibles = deudores.take(limite).toList();

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
          Text('Clientes con deuda', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.lg),
          if (visibles.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: Text(
                  'Sin saldos pendientes',
                  style: TextStyle(
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else
            for (final c in visibles) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    _Avatar(iniciales: c.iniciales),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.nombreMostrable,
                            style: AppTypography.small
                                .copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          Text(
                            '${c.totalOrdenes} pedido(s)',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      moneda.format(c.deudaTotal),
                      style: AppTypography.small.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (c != visibles.last)
                const Divider(height: 1, color: AppColors.border),
            ],
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.iniciales});
  final String iniciales;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary500.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Text(
        iniciales,
        style: AppTypography.small.copyWith(
          color: AppColors.primary600,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
