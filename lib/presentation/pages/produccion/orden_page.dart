// lib/presentation/pages/produccion/orden_page.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workspace/presentation/providers/orden_provider.dart';

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

// Vistas internas
import 'orden_detalle_page.dart';
import '../../components/ordenes/orden_form_page.dart';

// --- PÁGINA PRINCIPAL ---
class OrdenPage extends ConsumerStatefulWidget {
  const OrdenPage({super.key});

  @override
  ConsumerState<OrdenPage> createState() => _OrdenPageState();
}

class _OrdenPageState extends ConsumerState<OrdenPage> {
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  int _selectedFilter = 0; // 0: Todas, 1: Pendientes, 2: Producción, etc.

  // Estado interno: orden seleccionada para ver detalle.
  // Si es null, se muestra el listado. Si tiene valor, se muestra el detalle.
  OrdenModel? _ordenSeleccionada;
  bool _creandoOrden = false;

  void _abrirDetalle(OrdenModel orden) {
    setState(() => _ordenSeleccionada = orden);
  }

  void _volverAlListado() {
    setState(() => _ordenSeleccionada = null);
    setState(() => _creandoOrden = false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    if (_creandoOrden) {
      return OrdenFormPage(onVolver: _volverAlListado);
    }

    if (_ordenSeleccionada != null) {
      return OrdenDetallePage(
        orden: _ordenSeleccionada!,
        onVolver: _volverAlListado,
      );
    }

    if (_ordenSeleccionada != null) {
      return OrdenDetallePage(
        orden: _ordenSeleccionada!,
        onVolver: _volverAlListado,
      );
    }

    // Usamos el provider que creamos en el paso anterior
    final ordenesAsync = ref.watch(ordenesProvider);

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
                    setState(() => _creandoOrden = true);
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

    // MOBILE: grilla 2x2 con altura uniforme. La 3ra KPI ocupa toda la fila inferior.
    if (isMobile) {
      return Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: kpis[0]),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: kpis[1]),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          kpis[2], // tercer KPI a ancho completo
        ],
      );
    }

    // DESKTOP: 3 columnas en una sola fila
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
    // Formateador para el código corto
    final String displayCode = order.numOrden.length > 8
        ? order.numOrden.substring(0, 8).toUpperCase()
        : order.numOrden.toUpperCase();

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

          // CLIENTE (Usando el dato real de la BD)
          Expanded(
            flex: 3,
            child: Text(
              order.clienteNombre,
              style: AppTypography.small,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // PRODUCTO (Usando el dato real de la BD)
          Expanded(
            flex: 3,
            child: Text(
              order.producto,
              style: AppTypography.small.copyWith(color: AppColors.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // CANTIDAD (Usando el dato real de la BD)
          Expanded(
            flex: 2,
            child: Text(
              order.cantidad.toString(),
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
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              // Asegúrate de que este widget _StatusBadge acepte los parámetros correctos
              child: _StatusBadge(
                estado: order.estadoOrden,
                idEstado: order.idEstado,
              ),
            ),
          ),

          // ACCIONES (Usando el popup moderno en lugar del simple botón "Ver")
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'ver') onVerPressed();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'ver',
                    child: Text('Ver Detalles'),
                  ),
                ],
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
                _StatusBadge(idEstado: order.idEstado, estado: ''),
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
  final String estado;
  final int idEstado;

  const _StatusBadge({required this.estado, required this.idEstado});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;

    // Colores basados en el id del estado de tu base de datos
    switch (idEstado) {
      case 1: // Pendiente
        bgColor = Colors.orange.withOpacity(0.1);
        textColor = Colors.orange.shade800;
        break;
      case 2: // Producción
        bgColor = Colors.blue.withOpacity(0.1);
        textColor = Colors.blue.shade800;
        break;
      case 3: // Entregada
        bgColor = Colors.green.withOpacity(0.1);
        textColor = Colors.green.shade800;
        break;
      case 4: // Cancelada
        bgColor = Colors.red.withOpacity(0.1);
        textColor = Colors.red.shade800;
        break;
      default:
        bgColor = Colors.grey.withOpacity(0.1);
        textColor = Colors.grey.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        estado, // Aquí usamos el nombre real que viene de Supabase
        style: AppTypography.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
