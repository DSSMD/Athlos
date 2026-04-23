import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Agregado Riverpod

// --- TUS IMPORTS DE DISEÑO ---
// Asegúrate de que las rutas a tu theme y widgets sean correctas
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/users/kpi_card.dart';
import '../../widgets/users/search_input.dart';

// --- TUS IMPORTS DE DATOS (Rutas largas como definimos) ---
import '../../../domain/models/orden_model.dart';
import '../../../presentation/providers/orden_list_provider.dart';

/* // ══════════════════════════════════════════════════════════════════════════════
// CÓDIGO DE PRUEBA (MOCKS) COMENTADO - YA NO SE USA PORQUE TENEMOS SUPABASE
// ══════════════════════════════════════════════════════════════════════════════
enum EstadoOrden { pendiente, produccion, entregado, cancelado }
enum EstadoPago { pendiente, parcial, pagado }

class OrderMock {
  final String numOrden;
  final String idCliente;
  final String clienteNombre;
  final String clienteCi;
  final String producto;
  final int cantidad;
  final DateTime fechaOrden;
  final DateTime fechaEntrega;
  final double costoTotal;
  final EstadoOrden estadoOrden;
  final EstadoPago estadoPago;

  OrderMock({
    required this.numOrden, required this.idCliente, required this.clienteNombre,
    required this.clienteCi, required this.producto, required this.cantidad,
    required this.fechaOrden, required this.fechaEntrega, required this.costoTotal,
    required this.estadoOrden, required this.estadoPago,
  });
}

final List<OrderMock> mockOrders = List.generate(25, (index) { ... });
*/

// --- PÁGINA PRINCIPAL (Cambiado a ConsumerStatefulWidget para escuchar a Riverpod) ---
class OrdenesPage extends ConsumerStatefulWidget {
  const OrdenesPage({super.key});

  @override
  ConsumerState<OrdenesPage> createState() => _OrdenesPageState();
}

class _OrdenesPageState extends ConsumerState<OrdenesPage> {
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  int _selectedFilter = 0; // 0: Todas, 1: Pendientes...

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. ESCUCHAMOS LOS DATOS REALES DE SUPABASE
    final ordenesAsync = ref.watch(ordenListProvider);

    // 2. MANEJAMOS LOS ESTADOS DE CARGA
    return ordenesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: $error', style: const TextStyle(color: Colors.red)),
      ),
      data: (listaDeOrdenesReales) {
        // 3. SI HAY DATOS, CONSTRUIMOS EL DISEÑO DE TU COMPAÑERO
        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 900;

            // Lógica de Filtrado con datos reales
            final filteredOrders = listaDeOrdenesReales.where((o) {
              if (_selectedFilter == 0) return true;
              return o.idEstado == _selectedFilter;
            }).toList();

            // Cálculos de Paginación
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
                _StickyTopbar(
                  isMobile: isMobile,
                  searchController: _searchController,
                  onSearchChanged: (_) => setState(() => _currentPage = 1),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(
                      isMobile ? AppSpacing.lg : AppSpacing.xl2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _KpiRow(isMobile: isMobile),
                        const SizedBox(height: AppSpacing.xl),

                        _FilterChips(
                          selected: _selectedFilter,
                          onChanged: (i) => setState(() {
                            _selectedFilter = i;
                            _currentPage = 1;
                          }),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // --- LISTA / TABLA REAL ---
                        if (paginatedOrders.isEmpty)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.xl2),
                              child: Text("No se encontraron órdenes"),
                            ),
                          )
                        else if (isMobile)
                          _MobileList(orders: paginatedOrders)
                        else
                          _DesktopTable(orders: paginatedOrders),

                        const SizedBox(height: AppSpacing.xl),

                        // --- PAGINACIÓN DINÁMICA ---
                        if (isMobile)
                          _LoadMoreButton(
                            hasMore: _currentPage < totalPages,
                            onPressed: () => setState(() => _currentPage++),
                          )
                        else
                          _DesktopPagination(
                            currentPage: _currentPage,
                            totalPages: totalPages,
                            totalItems: totalItems,
                            itemsPerPage: _itemsPerPage,
                            onPageChanged: (page) =>
                                setState(() => _currentPage = page),
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
// COMPONENTES PRIVADOS DE LA PÁGINA (Sin Cambios Visuales)
// ══════════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header({
    required this.isMobile,
    required this.searchController,
    required this.onSearchChanged,
  });
  final bool isMobile;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final title = Text('Órdenes', style: AppTypography.h1);
    final btn = ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.add, size: 18),
      label: Text(isMobile ? 'Nueva' : 'Nueva Orden'),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: title),
              btn,
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SearchInput(
            hintText: 'Buscar orden...',
            controller: searchController,
            onChanged: onSearchChanged,
          ),
        ],
      );
    }

    return Row(
      children: [
        title,
        const Spacer(),
        SizedBox(
          width: 320,
          child: SearchInput(
            hintText: 'Buscar orden...',
            controller: searchController,
            onChanged: onSearchChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        btn,
      ],
    );
  }
}

class _StickyTopbar extends StatelessWidget {
  const _StickyTopbar({
    required this.isMobile,
    required this.searchController,
    required this.onSearchChanged,
  });
  final bool isMobile;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.lg : AppSpacing.xl2,
        vertical: isMobile ? AppSpacing.lg : AppSpacing.xl,
      ),
      child: _Header(
        isMobile: isMobile,
        searchController: searchController,
        onSearchChanged: onSearchChanged,
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onChanged;
  const _FilterChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final labels = [
      'Todas',
      'Pendientes',
      'Producción',
      'Entregadas',
      'Canceladas',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          labels.length,
          (i) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(labels[i]),
              selected: selected == i,
              onSelected: (_) => onChanged(i),
              // ignore: deprecated_member_use
              selectedColor: AppColors.primary500.withOpacity(0.1),
              labelStyle: TextStyle(
                color: selected == i
                    ? AppColors.primary500
                    : AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopPagination extends StatelessWidget {
  final int currentPage, totalPages, totalItems, itemsPerPage;
  final ValueChanged<int> onPageChanged;
  const _DesktopPagination({
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Mostrando ${(currentPage - 1) * itemsPerPage + 1} a ${currentPage * itemsPerPage > totalItems ? totalItems : currentPage * itemsPerPage} de $totalItems órdenes',
        ),
        Row(
          children: [
            IconButton(
              onPressed: currentPage > 1
                  ? () => onPageChanged(currentPage - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Text('Página $currentPage de $totalPages'),
            IconButton(
              onPressed: currentPage < totalPages
                  ? () => onPageChanged(currentPage + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiRow extends StatelessWidget {
  final bool isMobile;
  const _KpiRow({required this.isMobile});

  @override
  Widget build(BuildContext context) {
    final kpis = [
      KpiCard(
        value: '12',
        label: 'Pendientes',
        description: 'Por iniciar',
        valueColor: AppColors.warning,
      ),
      KpiCard(
        value: '5',
        label: 'Producción',
        description: 'En taller',
        valueColor: AppColors.info,
      ),
      KpiCard(
        value: 'Bs. 4500',
        label: 'Ventas',
        description: 'Este mes',
        valueColor: AppColors.success,
      ),
    ];

    return isMobile
        ? Column(
            children: kpis
                .map(
                  (k) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: k,
                  ),
                )
                .toList(),
          )
        : Row(
            children: kpis
                .map(
                  (k) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: k,
                    ),
                  ),
                )
                .toList(),
          );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// VISTAS DE DATOS ACTUALIZADAS A ORDENMODEL REAL
// ══════════════════════════════════════════════════════════════════════════════

// ══════════════════════════════════════════════════════════════════════════════
// VISTAS DE DATOS (REFLEJO FIEL A LA BD)
// ══════════════════════════════════════════════════════════════════════════════

class _DesktopTable extends StatelessWidget {
  const _DesktopTable({required this.orders});
  final List<OrdenModel> orders;

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
                _col('ID CLIENTE', 4), // Más ancho para el UUID
                _col('F. ORDEN', 2), // Agregamos la fecha de orden real
                _col('ENTREGA', 2),
                _col('ESTADOS', 2),
                _col('TOTAL', 2),
                const SizedBox(
                  width: 80,
                  child: Center(
                    child: Text(
                      'ACCIONES',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < orders.length; i++) ...[
            _OrderListRow(order: orders[i]),
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

class _OrderListRow extends StatelessWidget {
  final OrdenModel order;
  const _OrderListRow({required this.order});

  @override
  Widget build(BuildContext context) {
    String displayCode = order.numOrden.length > 8
        ? order.numOrden.substring(0, 8)
        : order.numOrden;

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
              displayCode.toUpperCase(),
              style: AppTypography.small.copyWith(fontWeight: FontWeight.bold),
            ),
          ),

          // ID CLIENTE (Crudo, sin texto extra)
          Expanded(
            flex: 4,
            child: Text(order.idCliente, style: AppTypography.caption),
          ),

          // FECHA ORDEN
          Expanded(
            flex: 2,
            child: Text(
              '${order.fechaOrden.day}/${order.fechaOrden.month}/${order.fechaOrden.year}',
              style: AppTypography.small,
            ),
          ),

          // FECHA ENTREGA
          Expanded(
            flex: 2,
            child: Text(
              '${order.fechaEntrega.day}/${order.fechaEntrega.month}/${order.fechaEntrega.year}',
              style: AppTypography.small,
            ),
          ),

          // ESTADOS (Orden y Pago)
          // ESTADOS (Orden y Pago)
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatusBadge(idEstado: order.idEstado),
                const SizedBox(height: 4),
                // Le pasamos el número directamente (puede ser nulo)
                _PagoBadge(idPago: order.idEstadoPago),
              ],
            ),
          ),

          // TOTAL
          Expanded(
            flex: 2,
            child: Text(
              'Bs. ${order.costoTotal.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),

          // ACCIONES
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.more_vert,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileList extends StatelessWidget {
  const _MobileList({required this.orders});
  final List<OrdenModel> orders; // CAMBIADO A OrdenModel

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < orders.length; i++) ...[
          _OrderCard(order: orders[i]),
          if (i < orders.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrdenModel order; // CAMBIADO A OrdenModel
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    String displayCode = order.numOrden.length > 8
        ? order.numOrden.substring(0, 8)
        : order.numOrden;

    return Container(
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
                displayCode.toUpperCase(),
                style: AppTypography.small.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  _PagoBadge(idPago: order.idEstadoPago),
                  const SizedBox(width: 4),
                  _StatusBadge(idEstado: order.idEstado),
                ],
              ),
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
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'ID: ${order.idCliente}',
                  style: AppTypography.body,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.inventory_2_outlined,
                size: 16,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Producto BD',
                  style: AppTypography.small.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: AppTypography.small.copyWith(color: AppColors.textMuted),
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
    );
  }
}
// ══════════════════════════════════════════════════════════════════════════════
// Añadido para mostrar estados de pago
// ══════════════════════════════════════════════════════════════════════════════

class _PagoBadge extends StatelessWidget {
  final int? idPago; // Ahora recibe un número que puede ser nulo
  const _PagoBadge({required this.idPago});

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.neutral500; // Color por defecto (gris)
    String label = 'N/A';

    // Mapeamos los IDs de tu base de datos
    if (idPago == 1) {
      color = AppColors.error; // Rojo
      label = 'PENDIENTE';
    } else if (idPago == 2) {
      color = AppColors.warning; // Naranja
      label = 'PARCIAL';
    } else if (idPago == 3) {
      color = AppColors.success; // Verde
      label = 'PAGADO';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        '\$ $label',
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }
}
// ══════════════════════════════════════════════════════════════════════════════
// BADGES ADAPTADOS (Reciben datos de Supabase en lugar de los Mocks)
// ══════════════════════════════════════════════════════════════════════════════

class _StatusBadge extends StatelessWidget {
  final int idEstado; // Recibe número de base de datos
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
        color: color.withOpacity(0.1),
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

/*
// ══════════════════════════════════════════════════════════════════════════════
// Se replico este mismo empezando desde la Linea 690 
// ══════════════════════════════════════════════════════════════════════════════

class _PagoBadge extends StatelessWidget {
  final String pago; // Recibe un String fijo por ahora
  const _PagoBadge({required this.pago});

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.warning; // Naranja genérico

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        '\$ $pago',
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 9,
        ),
      ),
    );
  }
}*/

class _LoadMoreButton extends StatelessWidget {
  const _LoadMoreButton({required this.hasMore, required this.onPressed});
  final bool hasMore;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (!hasMore) return const SizedBox.shrink();
    return Center(
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          'Cargar más...',
          style: AppTypography.small.copyWith(
            color: AppColors.primary500,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
