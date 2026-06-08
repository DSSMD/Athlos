// ============================================================================
// ventas_ordenes_recientes.dart
// Listado resumido de las órdenes más recientes para el dashboard de ventas.
// Tabla en desktop / cards en mobile, con chip de estado de color (mismo
// criterio de colores que el dashboard de administración).
// Recibe la lista ya ordenada desc por fecha (ordenesProvider la entrega así).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../../../theme/breakpoints.dart';
import '../../../../../domain/models/orden_model.dart';

class VentasOrdenesRecientes extends StatelessWidget {
  const VentasOrdenesRecientes({
    super.key,
    required this.ordenes,
    this.limite = 6,
  });

  final List<OrdenModel> ordenes;
  final int limite;

  @override
  Widget build(BuildContext context) {
    final visibles = ordenes.take(limite).toList();

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
          Text('Pedidos recientes', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.lg),
          if (visibles.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: Text('No hay pedidos registrados.')),
            )
          else if (context.isMobile)
            _ListaMobile(ordenes: visibles)
          else
            _TablaDesktop(ordenes: visibles),
        ],
      ),
    );
  }
}

class _TablaDesktop extends StatelessWidget {
  const _TablaDesktop({required this.ordenes});
  final List<OrdenModel> ordenes;

  @override
  Widget build(BuildContext context) {
    final moneda =
        NumberFormat.currency(symbol: 'Bs. ', decimalDigits: 2, locale: 'es_BO');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              _col('ORDEN', 2),
              _col('CLIENTE', 3),
              _col('FECHA', 2),
              _col('TOTAL', 2),
              _col('ESTADO', 2),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        for (final o in ordenes) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    _numCorto(o.numOrden),
                    style:
                        AppTypography.small.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    o.clienteNombre,
                    style: AppTypography.small,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(o.fechaOrden),
                    style: AppTypography.small,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    moneda.format(o.costoTotal),
                    style:
                        AppTypography.small.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: EstadoOrdenChip(
                    estadoLabel: o.estadoOrden,
                    idEstado: o.idEstado,
                  ),
                ),
              ],
            ),
          ),
          if (o != ordenes.last)
            const Divider(height: 1, color: AppColors.border),
        ],
      ],
    );
  }

  Widget _col(String label, int flex) => Expanded(
        flex: flex,
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
      );
}

class _ListaMobile extends StatelessWidget {
  const _ListaMobile({required this.ordenes});
  final List<OrdenModel> ordenes;

  @override
  Widget build(BuildContext context) {
    final moneda =
        NumberFormat.currency(symbol: 'Bs. ', decimalDigits: 2, locale: 'es_BO');

    return Column(
      children: [
        for (final o in ordenes) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _numCorto(o.numOrden),
                        style: AppTypography.body
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    EstadoOrdenChip(
                      estadoLabel: o.estadoOrden,
                      idEstado: o.idEstado,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${o.clienteNombre} · ${DateFormat('dd/MM/yyyy').format(o.fechaOrden)}',
                  style: AppTypography.small,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  moneda.format(o.costoTotal),
                  style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          if (o != ordenes.last)
            const Divider(height: 1, color: AppColors.border),
        ],
      ],
    );
  }
}

String _numCorto(String numOrden) {
  final base = numOrden.length > 8 ? numOrden.substring(0, 8) : numOrden;
  return '#${base.toUpperCase()}';
}

/// Chip de estado de orden. Mismo mapa de colores que el dashboard de admin:
/// 1 Pendiente · 2 En producción · 3 Finalizada · 4 Entregada.
class EstadoOrdenChip extends StatelessWidget {
  const EstadoOrdenChip({
    super.key,
    required this.estadoLabel,
    required this.idEstado,
  });
  final String estadoLabel;
  final int idEstado;

  @override
  Widget build(BuildContext context) {
    final color = switch (idEstado) {
      1 => Colors.orange,
      2 => AppColors.primary500,
      3 => Colors.green,
      4 => Colors.blue,
      _ => Colors.grey,
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          estadoLabel,
          style: AppTypography.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
