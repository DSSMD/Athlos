import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/models/inventario_item_model.dart';
import '../../../../../domain/models/movimiento_model.dart';
import '../../../../providers/movimiento_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../../../theme/breakpoints.dart';

/// Modal de visualización del historial de movimientos de un insumo.
///
/// Desktop: Dialog centrado. Mobile: fullscreen.
void showKardexHistorialModal(BuildContext context, InventarioItemModel item) {
  if (context.isMobile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => KardexHistorialModal(item: item, isMobile: true),
      ),
    );
  } else {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => KardexHistorialModal(item: item, isMobile: false),
    );
  }
}

class KardexHistorialModal extends ConsumerWidget {
  const KardexHistorialModal({
    super.key,
    required this.item,
    required this.isMobile,
  });

  final InventarioItemModel item;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movimientos = ref.watch(movimientosPorInsumoProvider(item.id));

    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildItemInfo(),
              const Divider(height: 1, color: AppColors.border),
              Expanded(child: _buildBody(movimientos)),
            ],
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context),
            _buildItemInfo(),
            const Divider(height: 1, color: AppColors.border),
            Flexible(child: _buildBody(movimientos)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Text('Historial', style: AppTypography.h2),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }

  Widget _buildItemInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.codigo,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(item.nombre, style: AppTypography.h3),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Stock actual',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${item.stockActual.toInt()} ${item.unidad}',
                style: AppTypography.h3.copyWith(color: AppColors.primary500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<MovimientoModel> movimientos) {
    if (movimientos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.history, size: 64, color: AppColors.textMuted),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Sin movimientos registrados',
                style: AppTypography.h3.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Los movimientos de este insumo aparecerán acá cuando se '
                'registren entradas o salidas.',
                style: AppTypography.small.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: const [
              _HeaderCell('FECHA', flex: 4),
              SizedBox(width: AppSpacing.sm),
              _HeaderCell('USUARIO', flex: 3),
              SizedBox(width: AppSpacing.sm),
              _HeaderCell('TIPO', flex: 2),
              SizedBox(width: AppSpacing.sm),
              _HeaderCell('CANTIDAD', flex: 3, align: TextAlign.right),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: movimientos.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.border),
            itemBuilder: (_, i) => _MovimientoRow(movimiento: movimientos[i]),
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {required this.flex, this.align = TextAlign.left});
  final String label;
  final int flex;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _MovimientoRow extends StatelessWidget {
  const _MovimientoRow({required this.movimiento});

  final MovimientoModel movimiento;

  @override
  Widget build(BuildContext context) {
    final isIngreso = movimiento.tipo == TipoMovimiento.ingreso;
    final color = isIngreso ? AppColors.success : AppColors.error;
    final signo = isIngreso ? '+' : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              _formatFecha(movimiento.fecha),
              style: AppTypography.small,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: Text(
              movimiento.usuario,
              style: AppTypography.small,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  movimiento.tipo.label,
                  style: AppTypography.caption.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: Text(
              '$signo${_formatCantidad(movimiento.cantidad)}',
              textAlign: TextAlign.right,
              style: AppTypography.small.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFecha(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final hh = d.hour.toString().padLeft(2, '0');
    final mn = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year} $hh:$mn';
  }

  String _formatCantidad(double n) {
    if (n == n.truncateToDouble()) return n.toInt().toString();
    return n.toStringAsFixed(2);
  }
}
