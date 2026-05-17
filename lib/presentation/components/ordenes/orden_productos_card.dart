// ============================================================================
// orden_productos_card.dart
// Ubicación: lib/presentation/components/ordenes/orden_productos_card.dart
// Descripción: Card "Ítems de la orden" del form Crear Orden.
//
// Refactor (esquema nuevo):
//   - Usa OrdenItemDraft (de orden_draft.dart) en lugar del legacy
//     OrdenProductoItem.
//   - Lee/escribe draft.items (campo nuevo) en lugar de draft.productos.
//   - Invoca AgregarItemDialog (archivo aparte) en lugar del dialog interno
//     legacy _AgregarProductoDialog (eliminado).
//
// Layout responsive:
//   - Desktop (>= 600px de ancho del card): tabla con
//     # / ÍTEM (nombre + tipo + tallas) / CANT / P. UNIT / SUBTOTAL / acción
//   - Mobile (< 600px): lista de mini-cards verticales con la misma info.
//
// Footer con total general (cantidad de unidades + suma en Bs.) si hay ítems.
// ============================================================================

import 'package:flutter/material.dart';

import '../../../domain/models/detalle_orden_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import 'agregar_item_dialog.dart';
import 'orden_draft.dart';

class OrdenProductosCard extends StatelessWidget {
  final OrdenDraft draft;
  final ValueChanged<OrdenDraft> onChanged;

  const OrdenProductosCard({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  static const double _compactBreakpoint = 600;

  // ─── Helpers de cálculo por ítem ───
  static int _cantidadTotal(OrdenItemDraft item) =>
      item.tallas.fold(0, (sum, t) => sum + t.cantidad);

  static double _subtotal(OrdenItemDraft item) =>
      item.precioUnitario * _cantidadTotal(item);

  static String _tallasResumen(OrdenItemDraft item) {
    if (item.tallas.isEmpty) return '—';
    return item.tallas.map((t) => '${t.nombreTalla}:${t.cantidad}').join(', ');
  }

  // ─── Acciones ───
  Future<void> _agregarItem(BuildContext context) async {
    final nuevo = await showDialog<OrdenItemDraft>(
      context: context,
      builder: (_) => const AgregarItemDialog(),
    );
    if (nuevo != null) {
      onChanged(draft.copyWith(items: [...draft.items, nuevo]));
    }
  }

  void _eliminarItem(int index) {
    final nuevaLista = [...draft.items]..removeAt(index);
    onChanged(draft.copyWith(items: nuevaLista));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < _compactBreakpoint;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context, isCompact),
              const SizedBox(height: AppSpacing.lg),
              if (draft.items.isEmpty)
                _empty()
              else if (isCompact)
                _listaMobile()
              else
                _tablaDesktop(),
              if (draft.items.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: AppSpacing.md),
                _totalRow(),
              ],
            ],
          );
        },
      ),
    );
  }

  // ─── HEADER ───
  Widget _header(BuildContext context, bool isCompact) {
    return Row(
      children: [
        Expanded(child: Text('Ítems de la orden', style: AppTypography.h3)),
        const SizedBox(width: AppSpacing.sm),
        if (isCompact)
          IconButton(
            onPressed: () => _agregarItem(context),
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.primary500,
            tooltip: 'Agregar ítem',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          )
        else
          TextButton.icon(
            onPressed: () => _agregarItem(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Agregar ítem'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary500),
          ),
      ],
    );
  }

  // ─── EMPTY ───
  Widget _empty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl2),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 32,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No hay ítems en la orden',
            style: AppTypography.small.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            'Agregá conjuntos o plantillas con el botón de arriba',
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  // ─── TABLA DESKTOP ───
  Widget _tablaDesktop() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              _col('#', 1),
              _col('ÍTEM', 6),
              _col('CANT.', 1),
              _col('P. UNIT.', 2),
              _col('SUBTOTAL', 2),
              const SizedBox(width: 48),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        for (var i = 0; i < draft.items.length; i++) ...[
          _ItemRowDesktop(
            index: i + 1,
            item: draft.items[i],
            onEliminar: () => _eliminarItem(i),
          ),
          if (i < draft.items.length - 1)
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

  // ─── LISTA MOBILE ───
  Widget _listaMobile() {
    return Column(
      children: [
        for (var i = 0; i < draft.items.length; i++) ...[
          _ItemRowMobile(
            index: i + 1,
            item: draft.items[i],
            onEliminar: () => _eliminarItem(i),
          ),
          if (i < draft.items.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  // ─── TOTAL ROW ───
  Widget _totalRow() {
    final totalUnidades = draft.items.fold<int>(
      0,
      (sum, it) => sum + _cantidadTotal(it),
    );
    final totalBs = draft.items.fold<double>(
      0.0,
      (sum, it) => sum + _subtotal(it),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Total $totalUnidades unidades',
          style: AppTypography.small.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(width: AppSpacing.lg),
        Text(
          'Bs. ${totalBs.toStringAsFixed(2)}',
          style: AppTypography.h3.copyWith(
            color: AppColors.primary500,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CHIP de tipo (CONJUNTO / PLANTILLA)
// ═════════════════════════════════════════════════════════════════════════════
Widget _tipoChip(TipoItem tipo) {
  final isConjunto = tipo == TipoItem.conjunto;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: isConjunto
          ? AppColors.primary500.withValues(alpha: 0.12)
          : AppColors.neutral100,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      isConjunto ? 'CONJUNTO' : 'PLANTILLA',
      style: AppTypography.caption.copyWith(
        color: isConjunto ? AppColors.primary500 : AppColors.textSecondary,
        fontWeight: FontWeight.w700,
        fontSize: 9,
        letterSpacing: 0.5,
      ),
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// FILA DESKTOP
// ═════════════════════════════════════════════════════════════════════════════
class _ItemRowDesktop extends StatelessWidget {
  final int index;
  final OrdenItemDraft item;
  final VoidCallback onEliminar;

  const _ItemRowDesktop({
    required this.index,
    required this.item,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final cant = OrdenProductosCard._cantidadTotal(item);
    final subtotal = OrdenProductosCard._subtotal(item);
    final tallas = OrdenProductosCard._tallasResumen(item);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 1, child: Text('$index', style: AppTypography.small)),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.nombre,
                        style: AppTypography.small.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _tipoChip(item.tipoItem),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  tallas,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(flex: 1, child: Text('$cant', style: AppTypography.small)),
          Expanded(
            flex: 2,
            child: Text(
              'Bs. ${item.precioUnitario.toStringAsFixed(2)}',
              style: AppTypography.small,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Bs. ${subtotal.toStringAsFixed(2)}',
              style: AppTypography.small.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 48,
            child: IconButton(
              onPressed: onEliminar,
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.error,
              tooltip: 'Eliminar',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// FILA MOBILE
// ═════════════════════════════════════════════════════════════════════════════
class _ItemRowMobile extends StatelessWidget {
  final int index;
  final OrdenItemDraft item;
  final VoidCallback onEliminar;

  const _ItemRowMobile({
    required this.index,
    required this.item,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    final cant = OrdenProductosCard._cantidadTotal(item);
    final subtotal = OrdenProductosCard._subtotal(item);
    final tallas = OrdenProductosCard._tallasResumen(item);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary500.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$index',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  item.nombre,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _tipoChip(item.tipoItem),
              IconButton(
                onPressed: onEliminar,
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.error,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Tallas: $tallas',
            style: AppTypography.small.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$cant uds × Bs. ${item.precioUnitario.toStringAsFixed(2)}',
                style: AppTypography.small.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'Bs. ${subtotal.toStringAsFixed(2)}',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
