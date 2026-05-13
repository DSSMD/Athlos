import 'package:flutter/material.dart';
import '../../../../../domain/models/inventario_model.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import 'kardex_historial_modal.dart';

void showInsumoDetalleModal(BuildContext context, InventarioItemModel item) {
  showDialog(
    context: context,
    builder: (ctx) => InsumoDetalleModal(item: item),
  );
}

class InsumoDetalleModal extends StatelessWidget {
  const InsumoDetalleModal({super.key, required this.item});
  final InventarioItemModel item;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${item.codigo} - ${item.nombre}',
                      style: AppTypography.h3,
                      maxLines: 2,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Text('Categoría: ${item.nombreCategoria}', style: AppTypography.body),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _InfoBox(
                      title: 'Stock Actual',
                      value: '${item.stockActual.toStringAsFixed(2)} ${item.unidad}',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _InfoBox(
                      title: 'Stock Mínimo',
                      value: '${item.stockMinimo.toStringAsFixed(2)} ${item.unidad}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _InfoBox(
                      title: 'CPP (Costo Unit.)',
                      value: 'Bs ${item.costoUnitario.toStringAsFixed(2)}',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _InfoBox(
                      title: 'Valor Inventario',
                      value: 'Bs ${item.valorTotal.toStringAsFixed(2)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  showKardexHistorialModal(context, item);
                },
                icon: const Icon(Icons.history),
                label: const Text('Ver Historial de Movimientos'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.title, required this.value});
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.caption.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
