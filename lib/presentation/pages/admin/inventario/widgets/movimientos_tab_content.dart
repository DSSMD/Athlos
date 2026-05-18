// lib/presentation/pages/admin/inventario/widgets/movimientos_tab_content.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/models/inventario_model.dart';
import '../../../../../domain/models/movimiento_model.dart';
import '../../../../providers/insumo_provider.dart';
import '../../../../providers/movimiento_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../../../widgets/users/kpi_card.dart';

class MovimientosTabContent extends ConsumerWidget {
  const MovimientosTabContent({super.key, required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncMovs = ref.watch(movimientoProvider);
    return asyncMovs.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Text(
            'Error al cargar movimientos: $e',
            style: AppTypography.body,
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (_) => _MovimientosBody(isMobile: isMobile),
    );
  }
}

// ─── BODY ─────────────────────────────────────────────────────────────────────

class _MovimientosBody extends ConsumerStatefulWidget {
  const _MovimientosBody({required this.isMobile});
  final bool isMobile;

  @override
  ConsumerState<_MovimientosBody> createState() => _MovimientosBodyState();
}

class _MovimientosBodyState extends ConsumerState<_MovimientosBody> {
  static const int _itemsPerPage = 8;
  int _currentPage = 1;

  void _resetPage() => setState(() => _currentPage = 1);

  @override
  Widget build(BuildContext context) {
    final isMobile = widget.isMobile;
    final kpis = ref.watch(movimientoKpisProvider);
    final filtrados = ref.watch(movimientosFiltradosProvider);
    final inventario =
        ref.watch(inventarioProvider).value ?? const <InventarioItemModel>[];
    final allMovs =
        ref.watch(movimientoProvider).value ?? const <MovimientoModel>[];

    final totalItems = filtrados.length;
    final totalPages = totalItems == 0
        ? 1
        : (totalItems / _itemsPerPage).ceil();
    if (_currentPage > totalPages) _currentPage = 1;
    final paginated = filtrados
        .skip((_currentPage - 1) * _itemsPerPage)
        .take(_itemsPerPage)
        .toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Kpis(isMobile: isMobile, kpis: kpis),
          const SizedBox(height: AppSpacing.xl),
          _TiposChipsRow(allMovimientos: allMovs, onChanged: _resetPage),
          const SizedBox(height: AppSpacing.lg),
          if (paginated.isEmpty)
            const _EmptyState()
          else if (isMobile)
            _MobileList(items: paginated, inventario: inventario)
          else
            _DesktopTable(items: paginated, inventario: inventario),
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

// ─── KPIs ─────────────────────────────────────────────────────────────────────

class _Kpis extends StatelessWidget {
  const _Kpis({required this.isMobile, required this.kpis});

  final bool isMobile;
  final MovimientoKpis kpis;

  @override
  Widget build(BuildContext context) {
    final cards = [
      KpiCard(
        value: '${kpis.entradasMes}',
        label: 'Entradas (mes)',
        description: '${_formatMoney(kpis.valorComprasMes)} en compras',
        valueColor: AppColors.success,
      ),
      KpiCard(
        value: '${kpis.salidasMes}',
        label: 'Salidas (mes)',
        description: 'Asignadas a producción',
        valueColor: AppColors.error,
      ),
    ];

    // Mobile y desktop usan el mismo patrón seguro `for (i; i < cards.length)`
    // para que agregar/quitar KPIs no rompa la fila. Antes el mobile path
    // accedía a `cards[0]` y `cards[1]` hardcoded; si el array de KPIs queda
    // con 1 elemento o crece, el patrón actual lo absorbe sin RangeError.
    if (isMobile) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i < cards.length - 1) const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
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

// ─── CHIPS POR TIPO ───────────────────────────────────────────────────────────

class _TiposChipsRow extends ConsumerWidget {
  const _TiposChipsRow({required this.allMovimientos, required this.onChanged});

  final List<MovimientoModel> allMovimientos;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activo = ref.watch(movimientoFiltrosProvider).tipo;
    final notifier = ref.read(movimientoFiltrosProvider.notifier);

    int countTipo(TipoMovimiento? t) => t == null
        ? allMovimientos.length
        : allMovimientos.where((m) => m.tipo == t).length;

    return Scrollbar(
      thumbVisibility: true,
      trackVisibility: true,
      thickness: 4,
      radius: const Radius.circular(2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          children: [
            _TipoChip(
              label: 'Todos',
              count: countTipo(null),
              active: activo == null,
              activeColor: AppColors.primary500,
              onTap: () {
                notifier.setTipo(null);
                onChanged();
              },
            ),
            // Solo mostramos chips para ingreso y salida. Los tipos `auto`
            // y `ajuste` siguen existiendo en el enum (el backend puede
            // generarlos internamente) pero el usuario no filtra por ellos
            // desde acá — decisión del equipo tras retroalimentación de Mel.
            for (final t in const [
              TipoMovimiento.ingreso,
              TipoMovimiento.salida,
            ]) ...[
              const SizedBox(width: AppSpacing.sm),
              _TipoChip(
                label: _tipoChipLabel(t),
                count: countTipo(t),
                active: activo == t,
                activeColor: _tipoColor(t),
                onTap: () {
                  notifier.setTipo(activo == t ? null : t);
                  onChanged();
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _tipoChipLabel(TipoMovimiento t) {
  switch (t) {
    case TipoMovimiento.ingreso:
      return 'Entradas';
    case TipoMovimiento.salida:
      return 'Salidas';
    case TipoMovimiento.auto:
      return 'Automáticos';
    case TipoMovimiento.ajuste:
      return 'Ajustes';
  }
}

class _TipoChip extends StatelessWidget {
  const _TipoChip({
    required this.label,
    required this.count,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = active ? activeColor : AppColors.background;
    final fg = active ? AppColors.brandWhite : AppColors.textSecondary;

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
            color: bg,
            border: Border.all(color: active ? activeColor : AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            '$label ($count)',
            style: AppTypography.small.copyWith(
              color: fg,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── EMPTY STATE ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
          const Icon(Icons.swap_horiz, size: 48, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text('No se encontraron movimientos', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Probá con otra búsqueda, área o tipo.',
            style: AppTypography.small,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── DESKTOP TABLE ────────────────────────────────────────────────────────────

const _kColFecha = 14;
const _kColTipo = 12;
const _kColInsumo = 18;
const _kColCantidad = 10;
const _kColStockAntes = 11;
const _kColReferencia = 12;
const _kColResponsable = 12;
const _kColGap = AppSpacing.sm;

class _DesktopTable extends StatelessWidget {
  const _DesktopTable({required this.items, required this.inventario});

  final List<MovimientoModel> items;
  final List<InventarioItemModel> inventario;

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
            child: Row(
              children: const [
                _HeaderCell('FECHA / HORA', flex: _kColFecha),
                SizedBox(width: _kColGap),
                _HeaderCell('TIPO', flex: _kColTipo, align: TextAlign.center),
                SizedBox(width: _kColGap),
                _HeaderCell(
                  'INSUMO',
                  flex: _kColInsumo,
                  align: TextAlign.center,
                ),
                SizedBox(width: _kColGap),
                _HeaderCell(
                  'CANTIDAD',
                  flex: _kColCantidad,
                  align: TextAlign.center,
                ),
                SizedBox(width: _kColGap),
                _HeaderCell(
                  'STOCK\nANTES',
                  flex: _kColStockAntes,
                  align: TextAlign.center,
                ),
                SizedBox(width: _kColGap),
                _HeaderCell(
                  'REFERENCIA',
                  flex: _kColReferencia,
                  align: TextAlign.center,
                ),
                SizedBox(width: _kColGap),
                _HeaderCell(
                  'RESPONSABLE',
                  flex: _kColResponsable,
                  align: TextAlign.center,
                ),
              ],
            ),
          ),
          for (var i = 0; i < items.length; i++) ...[
            _DesktopRow(item: items[i], inventario: inventario),
            if (i < items.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(
    this.label, {
    required this.flex,
    this.align = TextAlign.left,
  });

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
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DesktopRow extends StatelessWidget {
  const _DesktopRow({required this.item, required this.inventario});

  final MovimientoModel item;
  final List<InventarioItemModel> inventario;

  @override
  Widget build(BuildContext context) {
    final insumo = _lookupInsumo(inventario, item.idInsumo);
    final unidad = insumo?.unidad ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: _kColFecha,
            child: Text(
              _formatFechaHora(item.fecha),
              style: AppTypography.small,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: _kColGap),
          Expanded(
            flex: _kColTipo,
            child: Align(
              alignment: Alignment.center,
              child: _TipoBadge(tipo: item.tipo),
            ),
          ),
          const SizedBox(width: _kColGap),
          Expanded(
            flex: _kColInsumo,
            child: Text(
              insumo?.nombre ?? '—',
              style: AppTypography.small.copyWith(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: _kColGap),
          Expanded(
            flex: _kColCantidad,
            child: Text(
              _cantidadFormatted(item, unidad),
              textAlign: TextAlign.center,
              style: AppTypography.small.copyWith(
                color: _tipoColor(item.tipo),
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: _kColGap),
          Expanded(
            flex: _kColStockAntes,
            child: Text(
              '${_formatNumber(item.stockAntes)} $unidad',
              textAlign: TextAlign.center,
              style: AppTypography.small,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: _kColGap),
          Expanded(
            flex: _kColReferencia,
            child: Text(
              item.referencia,
              textAlign: TextAlign.center,
              style: AppTypography.small.copyWith(
                color: _referenciaColor(item.referencia),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: _kColGap),
          Expanded(
            flex: _kColResponsable,
            child: Text(
              item.usuario,
              textAlign: TextAlign.center,
              style: AppTypography.small,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── MOBILE LIST ──────────────────────────────────────────────────────────────

class _MobileList extends StatelessWidget {
  const _MobileList({required this.items, required this.inventario});

  final List<MovimientoModel> items;
  final List<InventarioItemModel> inventario;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          _MobileCard(item: items[i], inventario: inventario),
          if (i < items.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _MobileCard extends StatelessWidget {
  const _MobileCard({required this.item, required this.inventario});

  final MovimientoModel item;
  final List<InventarioItemModel> inventario;

  @override
  Widget build(BuildContext context) {
    final insumo = _lookupInsumo(inventario, item.idInsumo);
    final unidad = insumo?.unidad ?? '';

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
              _TipoBadge(tipo: item.tipo),
              const Spacer(),
              Text(
                _cantidadFormatted(item, unidad),
                style: AppTypography.body.copyWith(
                  color: _tipoColor(item.tipo),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(_formatFechaHora(item.fecha), style: AppTypography.caption),
          const SizedBox(height: AppSpacing.sm),
          Text(
            insumo?.nombre ?? '—',
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.referencia,
                  style: AppTypography.caption.copyWith(
                    color: _referenciaColor(item.referencia),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(item.usuario, style: AppTypography.caption),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.neutral50,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              'Stock antes: ${_formatNumber(item.stockAntes)} $unidad',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── BADGES ───────────────────────────────────────────────────────────────────

class _TipoBadge extends StatelessWidget {
  const _TipoBadge({required this.tipo});
  final TipoMovimiento tipo;

  @override
  Widget build(BuildContext context) {
    final color = _tipoColor(tipo);
    final icon = _tipoIcon(tipo);
    final label = _tipoBadgeLabel(tipo);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PAGINATION ───────────────────────────────────────────────────────────────

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
          'Mostrando $from-$to de $totalItems movimientos',
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
    if (total <= 7) return [for (var i = 1; i <= total; i++) i];
    final result = <int>[1];
    if (current > 3) result.add(-1);
    final start = (current - 1).clamp(2, total - 1);
    final end = (current + 1).clamp(2, total - 1);
    for (var i = start; i <= end; i++) {
      result.add(i);
    }
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

// ─── HELPERS ──────────────────────────────────────────────────────────────────

InventarioItemModel? _lookupInsumo(
  List<InventarioItemModel> inventario,
  String idInsumo,
) {
  final idx = inventario.indexWhere((i) => i.id == idInsumo);
  return idx == -1 ? null : inventario[idx];
}

Color _tipoColor(TipoMovimiento t) {
  switch (t) {
    case TipoMovimiento.ingreso:
      return AppColors.success;
    case TipoMovimiento.salida:
      return AppColors.error;
    case TipoMovimiento.auto:
      return const Color(0xFF7C3AED);
    case TipoMovimiento.ajuste:
      return AppColors.warning;
  }
}

IconData _tipoIcon(TipoMovimiento t) {
  switch (t) {
    case TipoMovimiento.ingreso:
      return Icons.arrow_upward;
    case TipoMovimiento.salida:
      return Icons.arrow_downward;
    case TipoMovimiento.auto:
      return Icons.refresh;
    case TipoMovimiento.ajuste:
      return Icons.tune;
  }
}

String _tipoBadgeLabel(TipoMovimiento t) {
  switch (t) {
    case TipoMovimiento.ingreso:
      return 'Entrada';
    case TipoMovimiento.salida:
      return 'Salida';
    case TipoMovimiento.auto:
      return 'Auto';
    case TipoMovimiento.ajuste:
      return 'Ajuste';
  }
}

Color _referenciaColor(String ref) {
  if (ref.startsWith('#ORD-') || ref.startsWith('Compra #')) {
    return AppColors.info;
  }
  if (ref == 'Sistema') return const Color(0xFF7C3AED);
  return AppColors.textSecondary;
}

String _cantidadFormatted(MovimientoModel m, String unidad) {
  // ingreso/ajuste: + (suma); salida/auto: - (resta).
  final esSuma =
      m.tipo == TipoMovimiento.ingreso || m.tipo == TipoMovimiento.ajuste;
  final signo = esSuma ? '+' : '-';
  final qty = _formatNumber(m.cantidad);
  return '$signo$qty${unidad.isEmpty ? '' : ' $unidad'}';
}

String _formatFechaHora(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  final hh = d.hour.toString().padLeft(2, '0');
  final mn = d.minute.toString().padLeft(2, '0');
  return '$dd/$mm $hh:$mn';
}

String _formatNumber(double n) {
  if (n == n.truncateToDouble()) return n.toInt().toString();
  return n.toStringAsFixed(2);
}

String _formatMoney(double n) {
  final entero = n.truncate();
  final s = entero.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '\$$buf';
}
