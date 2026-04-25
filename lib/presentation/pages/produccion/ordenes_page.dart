import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Tema
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

// Widgets compartidos (reutilizables entre módulos)
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/filter_chips.dart';
import '../../widgets/shared/pagination.dart';
import '../../widgets/shared/sticky_topbar.dart';

// Widgets específicos de usuarios (KpiCard — se comparte sin mover por ahora)
import '../../widgets/users/kpi_card.dart';

// Datos
import '../../../domain/models/orden_model.dart';
import '../../providers/orden_list_provider.dart';

// Vistas internas
import 'orden_detalle_page.dart';

// --- PÁGINA PRINCIPAL ---
class OrdenesPage extends ConsumerStatefulWidget {
  const OrdenesPage({super.key});

  @override
  ConsumerState<OrdenesPage> createState() => _OrdenesPageState();
}

class _OrdenesPageState extends ConsumerState<OrdenesPage> {
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  int _selectedFilter = 0; // 0: Todas, 1: Pendientes, 2: Producción, etc.

  // Estado interno: orden seleccionada para ver detalle.
  // Si es null, se muestra el listado. Si tiene valor, se muestra el detalle.
  OrdenModel? _ordenSeleccionada;

  void _abrirDetalle(OrdenModel orden) {
    setState(() => _ordenSeleccionada = orden);
  }

  void _volverAlListado() {
    setState(() => _ordenSeleccionada = null);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si hay orden seleccionada, mostramos el detalle
    if (_ordenSeleccionada != null) {
      return OrdenDetallePage(
        orden: _ordenSeleccionada!,
        onVolver: _volverAlListado,
      );
    }

    // Modo listado
    final ordenesAsync = ref.watch(ordenListProvider);

    return ordenesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
      ),
      data: (listaDeOrdenesReales) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 900;

            // Filtrado
            final filteredOrders = listaDeOrdenesReales.where((o) {
              if (_selectedFilter == 0) return true;
              return o.idEstado == _selectedFilter;
            }).toList();

            // Paginación
            final totalItems = filteredOrders.length;
            final totalPages = totalItems == 0
                ? 1
                : (totalItems / _itemsPerPage).ceil();

            final paginatedOrders = isMobile
                ? filteredOrders.take(_currentPage * _itemsPerPage).toList()
                : filteredOrders
                      .skip((_currentPage - 1) * _itemsPerPage)
                      .take(_itemsPerPage)
                      .toList();

            return Column(
              children: [
                StickyTopbar(
                  isMobile: isMobile,
                  title: 'Órdenes',
                  searchHint: 'Buscar orden, cliente...',
                  searchController: _searchController,
                  onSearchChanged: (_) => setState(() => _currentPage = 1),
                  newButtonLabelMobile: 'Nueva',
                  newButtonLabelDesktop: 'Nueva orden',
                  onNewPressed: () {
                    // TODO: abrir pantalla "Nueva orden" (SCRUM-75)
                  },
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(
                      isMobile ? AppSpacing.lg : AppSpacing.xl2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _KpiRow(
                          isMobile: isMobile,
                          pendientes: listaDeOrdenesReales
                              .where((o) => o.idEstado == 1)
                              .length,
                          enProduccion: listaDeOrdenesReales
                              .where((o) => o.idEstado == 2)
                              .length,
                          totalVentas: listaDeOrdenesReales
                              .fold<double>(0, (sum, o) => sum + o.costoTotal)
                              .toInt(),
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        FilterChips(
                          labels: const [
                            'Todas',
                            'Pendientes',
                            'Producción',
                            'Entregadas',
                            'Canceladas',
                          ],
                          counts: [
                            listaDeOrdenesReales.length,
                            listaDeOrdenesReales
                                .where((o) => o.idEstado == 1)
                                .length,
                            listaDeOrdenesReales
                                .where((o) => o.idEstado == 2)
                                .length,
                            listaDeOrdenesReales
                                .where((o) => o.idEstado == 3)
                                .length,
                            listaDeOrdenesReales
                                .where((o) => o.idEstado == 4)
                                .length,
                          ],
                          selected: _selectedFilter,
                          onChanged: (i) => setState(() {
                            _selectedFilter = i;
                            _currentPage = 1;
                          }),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        if (paginatedOrders.isEmpty)
                          const EmptyState(
                            icon: Icons.inbox_outlined,
                            title: 'No se encontraron órdenes',
                            subtitle:
                                'Probá con otro filtro o creá una nueva orden.',
                          )
                        else if (isMobile)
                          _MobileList(
                            orders: paginatedOrders,
                            onVerPressed: _abrirDetalle,
                          )
                        else
                          _DesktopTable(
                            orders: paginatedOrders,
                            onVerPressed: _abrirDetalle,
                          ),

                        const SizedBox(height: AppSpacing.xl),

                        if (isMobile)
                          LoadMoreButton(
                            hasMore: _currentPage < totalPages,
                            onPressed: () => setState(() => _currentPage++),
                          )
                        else
                          DesktopPagination(
                            currentPage: _currentPage,
                            totalPages: totalPages,
                            totalItems: totalItems,
                            itemsPerPage: _itemsPerPage,
                            onPageChanged: (page) =>
                                setState(() => _currentPage = page),
                            recordsLabel: 'órdenes',
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// KPI ROW
// ══════════════════════════════════════════════════════════════════════════════

class _KpiRow extends StatelessWidget {
  final bool isMobile;
  final int pendientes;
  final int enProduccion;
  final int totalVentas;

  const _KpiRow({
    required this.isMobile,
    required this.pendientes,
    required this.enProduccion,
    required this.totalVentas,
  });

  @override
  Widget build(BuildContext context) {
    final kpis = [
      KpiCard(
        value: '$pendientes',
        label: 'Pendientes',
        description: 'Por iniciar',
        valueColor: AppColors.warning,
      ),
      KpiCard(
        value: '$enProduccion',
        label: 'En producción',
        description: 'En taller',
        valueColor: AppColors.info,
      ),
      KpiCard(
        value: 'Bs. $totalVentas',
        label: 'Ventas',
        description: 'Acumulado',
        valueColor: AppColors.success,
      ),
    ];

    if (isMobile) {
      return Column(
        children: kpis
            .map(
              (k) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: k,
              ),
            )
            .toList(),
      );
    }
    return Row(
      children: [
        for (var i = 0; i < kpis.length; i++) ...[
          Expanded(child: kpis[i]),
          if (i < kpis.length - 1) const SizedBox(width: AppSpacing.lg),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DESKTOP TABLE
// ══════════════════════════════════════════════════════════════════════════════

class _DesktopTable extends StatelessWidget {
  const _DesktopTable({required this.orders, required this.onVerPressed});
  final List<OrdenModel> orders;
  final void Function(OrdenModel) onVerPressed;

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
              children: [
                _col('CÓDIGO', 2),
                _col('CLIENTE', 3),
                _col('PRODUCTO', 3),
                _col('CANTIDAD', 2),
                _col('TOTAL', 2),
                _col('ENTREGA', 2),
                _col('ESTADO', 2),
                SizedBox(
                  width: 60,
                  child: Text(
                    'ACCIONES',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < orders.length; i++) ...[
            _OrderListRow(
              order: orders[i],
              onVerPressed: () => onVerPressed(orders[i]),
            ),
            if (i < orders.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
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

// ══════════════════════════════════════════════════════════════════════════════
// ORDER LIST ROW (desktop)
// ══════════════════════════════════════════════════════════════════════════════

class _OrderListRow extends StatelessWidget {
  final OrdenModel order;
  final VoidCallback onVerPressed;

  const _OrderListRow({required this.order, required this.onVerPressed});

  @override
  Widget build(BuildContext context) {
    final String displayCode = order.numOrden.length > 8
        ? order.numOrden.substring(0, 8).toUpperCase()
        : order.numOrden.toUpperCase();

    // TODO(SCRUM-72): Los campos 'nombreCliente', 'producto' y 'cantidad' no
    // existen en OrdenModel. Requieren joins con la tabla 'cliente' y con
    // las tablas de líneas/items. Por ahora se muestran placeholders.
    final String clienteDisplay = 'Cliente #${order.idCliente.substring(0, 6)}';
    const String productoDisplay = '—';
    const String cantidadDisplay = '—';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // CÓDIGO
          Expanded(
            flex: 2,
            child: Text(
              '#$displayCode',
              style: AppTypography.small.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary500,
              ),
            ),
          ),

          // CLIENTE
          Expanded(
            flex: 3,
            child: Text(
              clienteDisplay,
              style: AppTypography.small,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // PRODUCTO
          Expanded(
            flex: 3,
            child: Text(
              productoDisplay,
              style: AppTypography.small.copyWith(color: AppColors.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // CANTIDAD
          Expanded(
            flex: 2,
            child: Text(
              cantidadDisplay,
              style: AppTypography.small.copyWith(color: AppColors.textMuted),
            ),
          ),

          // TOTAL
          Expanded(
            flex: 2,
            child: Text(
              'Bs. ${order.costoTotal.toStringAsFixed(2)}',
              style: AppTypography.small.copyWith(fontWeight: FontWeight.w600),
            ),
          ),

          // ENTREGA
          Expanded(
            flex: 2,
            child: Text(
              '${order.fechaEntrega.day.toString().padLeft(2, '0')}/'
              '${order.fechaEntrega.month.toString().padLeft(2, '0')}/'
              '${order.fechaEntrega.year}',
              style: AppTypography.small,
            ),
          ),

          // ESTADO
          Expanded(flex: 2, child: _StatusBadge(idEstado: order.idEstado)),

          // ACCIONES — botón "Ver"
          SizedBox(
            width: 60,
            child: Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: onVerPressed,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Ver'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MOBILE LIST
// ══════════════════════════════════════════════════════════════════════════════

class _MobileList extends StatelessWidget {
  const _MobileList({required this.orders, required this.onVerPressed});
  final List<OrdenModel> orders;
  final void Function(OrdenModel) onVerPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < orders.length; i++) ...[
          _OrderCard(
            order: orders[i],
            onVerPressed: () => onVerPressed(orders[i]),
          ),
          if (i < orders.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ORDER CARD (mobile)
// ══════════════════════════════════════════════════════════════════════════════

class _OrderCard extends StatelessWidget {
  final OrdenModel order;
  final VoidCallback onVerPressed;

  const _OrderCard({required this.order, required this.onVerPressed});

  @override
  Widget build(BuildContext context) {
    final String displayCode = order.numOrden.length > 8
        ? order.numOrden.substring(0, 8).toUpperCase()
        : order.numOrden.toUpperCase();

    final String clienteDisplay = 'Cliente #${order.idCliente.substring(0, 6)}';

    return InkWell(
      onTap: onVerPressed,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#$displayCode',
                  style: AppTypography.small.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary500,
                  ),
                ),
                _StatusBadge(idEstado: order.idEstado),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    clienteDisplay,
                    style: AppTypography.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            Row(
              children: [
                const Icon(
                  Icons.inventory_2_outlined,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '—',
                    style: AppTypography.small.copyWith(
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Entrega: '
                  '${order.fechaEntrega.day.toString().padLeft(2, '0')}/'
                  '${order.fechaEntrega.month.toString().padLeft(2, '0')}/'
                  '${order.fechaEntrega.year}',
                  style: AppTypography.small.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),

            const Divider(height: AppSpacing.xl),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: AppTypography.small.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  'Bs. ${order.costoTotal.toStringAsFixed(2)}',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// STATUS BADGE
// ══════════════════════════════════════════════════════════════════════════════

class _StatusBadge extends StatelessWidget {
  final int idEstado;
  const _StatusBadge({required this.idEstado});

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.neutral500;
    String label = 'ESTADO $idEstado';

    switch (idEstado) {
      case 1:
        color = AppColors.warning;
        label = 'PENDIENTE';
        break;
      case 2:
        color = AppColors.info;
        label = 'PRODUCCIÓN';
        break;
      case 3:
        color = AppColors.success;
        label = 'ENTREGADO';
        break;
      case 4:
        color = AppColors.error;
        label = 'CANCELADO';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
