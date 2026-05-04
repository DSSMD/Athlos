// lib/presentation/pages/admin/inventario/widgets/stock_tab_content.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/models/inventario_item_model.dart';
import '../../../../providers/inventario_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../../../widgets/users/kpi_card.dart';

class StockTabContent extends ConsumerWidget {
  const StockTabContent({super.key, required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(inventarioProvider);

    return asyncItems.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Text(
            'Error al cargar inventario: $e',
            style: AppTypography.body,
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (_) {
        final filtered = ref.watch(inventarioFiltradoProvider);
        final kpis = ref.watch(inventarioKpisProvider);

        return _StockBody(isMobile: isMobile, filtered: filtered, kpis: kpis);
      },
    );
  }
}

class _StockBody extends ConsumerStatefulWidget {
  const _StockBody({
    required this.isMobile,
    required this.filtered,
    required this.kpis,
  });

  final bool isMobile;
  final List<InventarioItemModel> filtered;
  final InventarioKpis kpis;

  @override
  ConsumerState<_StockBody> createState() => _StockBodyState();
}

class _StockBodyState extends ConsumerState<_StockBody> {
  static const int _itemsPerPage = 8;
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    final filtered = widget.filtered;
    final filtros = ref.watch(inventarioFiltrosProvider);
    final isMobile = widget.isMobile;

    final totalItems = filtered.length;
    final totalPages = totalItems == 0
        ? 1
        : (totalItems / _itemsPerPage).ceil();
    if (_currentPage > totalPages) _currentPage = 1;
    final paginated = filtered
        .skip((_currentPage - 1) * _itemsPerPage)
        .take(_itemsPerPage)
        .toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Kpis(isMobile: isMobile, kpis: widget.kpis),
          const SizedBox(height: AppSpacing.xl),
          _FiltrosCard(
            isMobile: isMobile,
            filtros: filtros,
            totalResultados: totalItems,
            onPageReset: () => setState(() => _currentPage = 1),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (paginated.isEmpty)
            _EmptyState()
          else if (isMobile)
            _MobileItemsList(items: paginated)
          else
            _DesktopItemsTable(items: paginated),
          const SizedBox(height: AppSpacing.xl),
          _Pagination(
            currentPage: _currentPage,
            totalPages: totalPages,
            totalItems: totalItems,
            itemsPerPage: _itemsPerPage,
            onPageChanged: (p) => setState(() => _currentPage = p),
          ),
        ],
      ),
    );
  }
}

// ─── KPIs ────────────────────────────────────────────────────────────────────

class _Kpis extends StatelessWidget {
  const _Kpis({required this.isMobile, required this.kpis});

  final bool isMobile;
  final InventarioKpis kpis;

  @override
  Widget build(BuildContext context) {
    final cards = [
      KpiCard(
        value: '${kpis.totalInsumos}',
        label: 'Total insumos',
        description: 'En 8 categorías',
      ),
      KpiCard(
        value: '${kpis.stockBajo}',
        label: 'Stock bajo',
        description: 'Requieren compra',
        valueColor: AppColors.warning,
      ),
      KpiCard(
        value: '${kpis.stockCritico}',
        label: 'Stock crítico',
        description: 'Urgente',
        valueColor: AppColors.error,
      ),
      KpiCard(
        value: _formatMoney(kpis.valorTotalInventario),
        label: 'Valor total inventario',
        description: '+\$0 este mes',
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: cards[1]),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[2]),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: cards[3]),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: AppSpacing.lg),
        ],
      ],
    );
  }
}

// ─── FILTROS ─────────────────────────────────────────────────────────────────

class _FiltrosCard extends ConsumerWidget {
  const _FiltrosCard({
    required this.isMobile,
    required this.filtros,
    required this.totalResultados,
    required this.onPageReset,
  });

  final bool isMobile;
  final InventarioFiltros filtros;
  final int totalResultados;
  final VoidCallback onPageReset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtrosNotifier = ref.read(inventarioFiltrosProvider.notifier);
    final categoriaActivaLabel = filtros.categoria?.label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Chips de categoría + link "Limpiar filtros" alineado derecha
        Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _CategoriaChip(
                      label: 'Todos',
                      active:
                          filtros.categoria == null && !filtros.stockBajoOnly,
                      onTap: () {
                        filtrosNotifier.setCategoria(null);
                        if (filtros.stockBajoOnly) {
                          filtrosNotifier.toggleStockBajo();
                        }
                        onPageReset();
                      },
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _CategoriaChip(
                      label: 'Stock bajo',
                      active: filtros.stockBajoOnly,
                      onTap: () {
                        filtrosNotifier.toggleStockBajo();
                        onPageReset();
                      },
                    ),
                    for (final cat in const [
                      CategoriaInsumo.telas,
                      CategoriaInsumo.hilos,
                      CategoriaInsumo.accesorios,
                      CategoriaInsumo.etiquetas,
                      CategoriaInsumo.empaque,
                    ]) ...[
                      const SizedBox(width: AppSpacing.sm),
                      _CategoriaChip(
                        label: cat.label,
                        active: filtros.categoria == cat,
                        onTap: () {
                          filtrosNotifier.setCategoria(
                            filtros.categoria == cat ? null : cat,
                          );
                          onPageReset();
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (filtros.hasFiltros)
              TextButton(
                onPressed: () {
                  filtrosNotifier.limpiar();
                  onPageReset();
                },
                child: const Text('Limpiar filtros'),
              ),
          ],
        ),
        if (filtros.hasFiltros) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            _resultadosLabel(
              total: totalResultados,
              query: filtros.query,
              categoria: categoriaActivaLabel,
              stockBajoOnly: filtros.stockBajoOnly,
            ),
            style: AppTypography.caption,
          ),
        ],
      ],
    );
  }

  String _resultadosLabel({
    required int total,
    required String query,
    String? categoria,
    required bool stockBajoOnly,
  }) {
    final partes = <String>[];
    if (query.trim().isNotEmpty) partes.add("'${query.trim()}'");
    if (categoria != null) partes.add('en categoría $categoria');
    if (stockBajoOnly) partes.add('con stock bajo');
    final detalle = partes.isEmpty ? '' : ' para ${partes.join(' ')}';
    return 'Mostrando $total resultados$detalle';
  }
}

class _CategoriaChip extends StatelessWidget {
  const _CategoriaChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: active ? AppColors.primary500 : AppColors.neutral200,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            label,
            style: AppTypography.small.copyWith(
              color: active ? AppColors.brandWhite : AppColors.neutral600,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── EMPTY STATE ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl3),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('No se encontraron insumos', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Probá con otra búsqueda o categoría.',
            style: AppTypography.small,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── DESKTOP TABLE ───────────────────────────────────────────────────────────

// Pesos de columna compartidos entre header y filas para que todo se alinee.
const _kColCodigo = 10;
const _kColInsumo = 25;
const _kColCategoria = 16;
const _kColStock = 10;
const _kColNivel = 30;
const _kColMinimo = 10;
const _kColUnidad = 12;
const _kColCosto = 12;
const _kColValor = 14;
const _kColEstado = 13;
const _kColEditar = 8;
const _kColGap = AppSpacing.md;
// Gap más amplio entre STOCK y NIVEL para que no se peguen visualmente.
const _kColGapWide = AppSpacing.xl;

class _DesktopItemsTable extends StatelessWidget {
  const _DesktopItemsTable({required this.items});

  final List<InventarioItemModel> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  _HeaderCell(label: 'CÓDIGO', flex: _kColCodigo),
                  SizedBox(width: _kColGap),
                  _HeaderCell(label: 'INSUMO', flex: _kColInsumo),
                  SizedBox(width: _kColGap),
                  _HeaderCell(label: 'CATEGORÍA', flex: _kColCategoria),
                  SizedBox(width: _kColGap),
                  _HeaderCell(
                    label: 'STOCK\nACTUAL',
                    flex: _kColStock,
                    align: TextAlign.center,
                  ),
                  SizedBox(width: _kColGapWide),
                  _HeaderCell(label: 'NIVEL', flex: _kColNivel),
                  SizedBox(width: _kColGap),
                  _HeaderCell(
                    label: 'MÍNIMO',
                    flex: _kColMinimo,
                    align: TextAlign.center,
                  ),
                  SizedBox(width: _kColGap),
                  _HeaderCell(label: 'UNIDAD', flex: _kColUnidad),
                  SizedBox(width: _kColGap),
                  _HeaderCell(
                    label: 'COSTO\nUNIT.',
                    flex: _kColCosto,
                    align: TextAlign.center,
                  ),
                  SizedBox(width: _kColGap),
                  _HeaderCell(
                    label: 'VALOR\nTOTAL',
                    flex: _kColValor,
                    align: TextAlign.center,
                  ),
                  SizedBox(width: _kColGap),
                  _HeaderCell(
                    label: 'ESTADO',
                    flex: _kColEstado,
                    align: TextAlign.center,
                  ),
                  SizedBox(width: _kColGap),
                  _HeaderCell(
                    label: 'EDITAR',
                    flex: _kColEditar,
                    align: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            _DesktopRow(item: items[i]),
            if (i < items.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.label,
    required this.flex,
    this.align = TextAlign.left,
  });

  final String label;
  final int flex;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final alignment = align == TextAlign.right
        ? Alignment.bottomRight
        : align == TextAlign.center
        ? Alignment.bottomCenter
        : Alignment.bottomLeft;

    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignment,
        child: Text(
          label,
          textAlign: align,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _DesktopRow extends StatelessWidget {
  const _DesktopRow({required this.item});

  final InventarioItemModel item;

  @override
  Widget build(BuildContext context) {
    final estadoColor = _stockStateColor(item.estado);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: _kColCodigo,
            child: Text(
              item.codigo,
              style: AppTypography.small.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: _kColGap),
          Expanded(
            flex: _kColInsumo,
            child: Text(
              item.nombre,
              style: AppTypography.small,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: _kColGap),
          Expanded(
            flex: _kColCategoria,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _CategoriaBadge(categoria: item.categoria),
            ),
          ),
          const SizedBox(width: _kColGap),
          Expanded(
            flex: _kColStock,
            child: Text(
              _formatNumber(item.stockActual),
              textAlign: TextAlign.center,
              style: AppTypography.small.copyWith(
                color: estadoColor,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: _kColGapWide),
          Expanded(
            flex: _kColNivel,
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: LinearProgressIndicator(
                      value: (item.nivelPorcentaje / 100)
                          .clamp(0, 1)
                          .toDouble(),
                      minHeight: 6,
                      backgroundColor: AppColors.neutral100,
                      valueColor: AlwaysStoppedAnimation(estadoColor),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: 44,
                  child: Text(
                    _formatPorcentaje(item.nivelPorcentaje),
                    textAlign: TextAlign.right,
                    style: AppTypography.small.copyWith(
                      color: estadoColor,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: _kColGap),
          Expanded(
            flex: _kColMinimo,
            child: Text(
              _formatNumber(item.stockMinimo),
              textAlign: TextAlign.center,
              style: AppTypography.small,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: _kColGap),
          Expanded(
            flex: _kColUnidad,
            child: Text(
              item.unidad,
              style: AppTypography.small,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: _kColGap),
          Expanded(
            flex: _kColCosto,
            child: Text(
              _formatMoney(item.costoUnitario),
              textAlign: TextAlign.center,
              style: AppTypography.small,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: _kColGap),
          Expanded(
            flex: _kColValor,
            child: Text(
              _formatMoney(item.valorTotal),
              textAlign: TextAlign.center,
              style: AppTypography.small.copyWith(fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: _kColGap),
          Expanded(
            flex: _kColEstado,
            child: Align(
              alignment: Alignment.center,
              child: _EstadoChip(estado: item.estado),
            ),
          ),
          const SizedBox(width: _kColGap),
          Expanded(
            flex: _kColEditar,
            child: Center(
              child: TextButton(
                onPressed: () => _todoEditar(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Editar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── MOBILE LIST ─────────────────────────────────────────────────────────────

class _MobileItemsList extends StatelessWidget {
  const _MobileItemsList({required this.items});

  final List<InventarioItemModel> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _MobileItemCard(item: items[i]),
          if (i < items.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _MobileItemCard extends StatelessWidget {
  const _MobileItemCard({required this.item});

  final InventarioItemModel item;

  @override
  Widget build(BuildContext context) {
    final estadoColor = _stockStateColor(item.estado);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                item.codigo,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  item.nombre,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _CategoriaBadge(categoria: item.categoria),
              const SizedBox(width: AppSpacing.sm),
              _EstadoChip(estado: item.estado),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stock', style: AppTypography.caption),
                    Text(
                      '${_formatNumber(item.stockActual)} ${item.unidad}',
                      style: AppTypography.small.copyWith(
                        color: estadoColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mínimo', style: AppTypography.caption),
                    Text(
                      '${_formatNumber(item.stockMinimo)} ${item.unidad}',
                      style: AppTypography.small,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: LinearProgressIndicator(
              value: (item.nivelPorcentaje / 100).clamp(0, 1).toDouble(),
              minHeight: 6,
              backgroundColor: AppColors.neutral100,
              valueColor: AlwaysStoppedAnimation(estadoColor),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Costo unitario', style: AppTypography.caption),
                    Text(
                      _formatMoney(item.costoUnitario),
                      style: AppTypography.small,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Valor total', style: AppTypography.caption),
                    Text(
                      _formatMoney(item.valorTotal),
                      style: AppTypography.small.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => _todoEditar(context),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Editar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── BADGES / CHIPS ──────────────────────────────────────────────────────────

class _CategoriaBadge extends StatelessWidget {
  const _CategoriaBadge({required this.categoria});

  final CategoriaInsumo categoria;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        categoria.label,
        style: AppTypography.caption.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.estado});

  final StockState estado;

  @override
  Widget build(BuildContext context) {
    final color = _stockStateColor(estado);
    final label = _stockStateLabel(estado);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

// ─── PAGINATION ──────────────────────────────────────────────────────────────

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.onPageChanged,
  });

  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (totalItems == 0) return const SizedBox.shrink();

    final from = (currentPage - 1) * itemsPerPage + 1;
    final to = (currentPage * itemsPerPage).clamp(0, totalItems);

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: AppSpacing.sm,
      children: [
        Text(
          'Mostrando $from-$to de $totalItems insumos',
          style: AppTypography.caption,
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final p in _visiblePages(currentPage, totalPages)) ...[
              if (p == -1)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  child: Text('...'),
                )
              else
                _PageButton(
                  page: p,
                  active: p == currentPage,
                  onTap: () => onPageChanged(p),
                ),
              const SizedBox(width: AppSpacing.xs),
            ],
          ],
        ),
      ],
    );
  }

  List<int> _visiblePages(int current, int total) {
    if (total <= 7) {
      return [for (var i = 1; i <= total; i++) i];
    }
    final result = <int>[1];
    if (current > 3) result.add(-1);
    final start = (current - 1).clamp(2, total - 1);
    final end = (current + 1).clamp(2, total - 1);
    for (var i = start; i <= end; i++) result.add(i);
    if (current < total - 2) result.add(-1);
    result.add(total);
    return result;
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.page,
    required this.active,
    required this.onTap,
  });

  final int page;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.primary500 : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(
              color: active ? AppColors.primary500 : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            '$page',
            style: AppTypography.small.copyWith(
              color: active ? AppColors.brandWhite : AppColors.textPrimary,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── HELPERS ─────────────────────────────────────────────────────────────────

Color _stockStateColor(StockState s) {
  switch (s) {
    case StockState.critico:
      return AppColors.error;
    case StockState.bajo:
      return AppColors.warning;
    case StockState.alerta:
      return AppColors.warning;
    case StockState.ok:
      return AppColors.success;
  }
}

String _stockStateLabel(StockState s) {
  switch (s) {
    case StockState.critico:
      return 'Crítico';
    case StockState.bajo:
      return 'Bajo';
    case StockState.alerta:
      return 'Alerta';
    case StockState.ok:
      return 'OK';
  }
}

String _formatNumber(double n) {
  if (n == n.truncateToDouble()) return n.toInt().toString();
  return n.toStringAsFixed(2);
}

String _formatPorcentaje(double n) {
  if (n > 999) return '>999%';
  return '${n.toStringAsFixed(0)}%';
}

String _formatMoney(double n) {
  // Simple formato: \$1.234 (sin decimales si entero)
  final entero = n.truncate();
  final s = entero.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '\$$buf';
}

void _todoEditar(BuildContext context) {
  // TODO: implementar modal de edición de insumo en próximo sprint.
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Editar insumo — pendiente'),
      duration: Duration(seconds: 2),
    ),
  );
}
