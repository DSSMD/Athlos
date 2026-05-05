import 'package:flutter/material.dart';

import '../../../../../domain/models/inventario_item_model.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../../../theme/breakpoints.dart';

/// Modal de visualización del historial de movimientos de un insumo.
///
/// En desktop se muestra como Dialog centrado.
/// En mobile se muestra fullscreen.
///
/// Por ahora SIN DATOS — empty state. Cuando backend exponga la
/// tabla `movimiento_insumo`, conectar acá.
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

class KardexHistorialModal extends StatelessWidget {
  const KardexHistorialModal({
    super.key,
    required this.item,
    required this.isMobile,
  });

  final InventarioItemModel item;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildItemInfo(),
              const Divider(height: 1, color: AppColors.border),
              Expanded(child: _buildBody()),
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
            Flexible(child: _buildBody()),
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

  Widget _buildBody() {
    // TODO: cuando backend exponga movimiento_insumo de este item,
    // construir tabla con: fecha, usuario, tipo (ingreso/salida), cantidad.
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
}
