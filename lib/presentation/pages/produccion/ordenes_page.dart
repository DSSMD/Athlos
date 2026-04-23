import 'package:flutter/material.dart';
// Importa tus widgets de diseño ya creados
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/users/kpi_card.dart';
import '../../widgets/users/search_input.dart';

// --- MOCKS TEMPORALES BASADOS EN EL ESQUEMA SQL REAL ---

enum EstadoOrden { pendiente, produccion, entregado, cancelado }

enum EstadoPago { pendiente, parcial, pagado }

class OrderMock {
  final String numOrden; // -> CÓDIGO
  final String idCliente;
  final String clienteNombre; // -> CLIENTE
  final String clienteCi;
  final String producto; // -> NUEVO: PRODUCTO
  final int cantidad; // -> NUEVO: CANTIDAD
  final DateTime fechaOrden;
  final DateTime fechaEntrega; // -> ENTREGA
  final double costoTotal; // -> TOTAL
  final EstadoOrden estadoOrden; // -> ESTADO
  final EstadoPago estadoPago; // -> ESTADO

  OrderMock({
    required this.numOrden,
    required this.idCliente,
    required this.clienteNombre,
    required this.clienteCi,
    required this.producto,
    required this.cantidad,
    required this.fechaOrden,
    required this.fechaEntrega,
    required this.costoTotal,
    required this.estadoOrden,
    required this.estadoPago,
  });
}

// Generador de datos actualizado
final List<OrderMock> mockOrders = List.generate(25, (index) {
  final String pseudoUuid = '550e8400-e29b-41d4-a716-${446655440000 + index}';

  return OrderMock(
    numOrden: pseudoUuid,
    idCliente: 'cliente-uuid-${index % 5}',
    clienteNombre: index % 3 == 0 ? 'Taller Central' : 'Juan Pérez',
    clienteCi: '789456${index} LP',
    producto: index % 2 == 0
        ? 'Polera Deportiva'
        : 'Chamarra de Invierno', // Mock producto
    cantidad: (index % 5) + 1, // Mock cantidad (1 a 5)
    fechaOrden: DateTime.now().subtract(Duration(days: index)),
    fechaEntrega: DateTime.now().add(Duration(days: 7 - (index % 10))),
    costoTotal: 150.0 + (index * 15.5),
    estadoOrden: EstadoOrden.values[index % 4],
    estadoPago: EstadoPago.values[index % 3],
  );
});

// --- PÁGINA PRINCIPAL ---
class OrdenesPage extends StatefulWidget {
  const OrdenesPage({super.key});

  @override
  State<OrdenesPage> createState() => _OrdenesPageState();
}

class _OrdenesPageState extends State<OrdenesPage> {
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        // 1. Lógica de Filtrado (Simulada)
        final filteredOrders = mockOrders.where((o) {
          if (_selectedFilter == 0) return true;
          return o.estadoOrden.index == (_selectedFilter - 1);
        }).toList();

        // 2. Cálculos de Paginación (Tu módulo)
        final totalItems = filteredOrders.length;
        final totalPages = (totalItems / _itemsPerPage).ceil();

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

                    // --- LISTA / TABLA ---
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
  }
}
// --- COMPONENTES PRIVADOS DE LA PÁGINA ---

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
      onPressed: () {}, // Aquí irá el showOrderFormDrawer
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

// --- COMPONENTES DE TABLA Y LISTA ---

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

// --- KPI ROW (Basado en tu diseño de Usuarios) ---
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
// DESKTOP TABLE — header + filas
// ══════════════════════════════════════════════════════════════════════════════

class _DesktopTable extends StatelessWidget {
  const _DesktopTable({required this.orders});
  final List<OrderMock> orders;

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
          // Header adaptado a tus nuevos campos
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
                _col('CANT.', 1),
                _col('ENTREGA', 2),
                _col('ESTADO', 2),
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
          // Filas
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

// ══════════════════════════════════════════════════════════════════════════════
// FILA DE TABLA DESKTOP
// ══════════════════════════════════════════════════════════════════════════════

class _OrderListRow extends StatelessWidget {
  final OrderMock order;
  const _OrderListRow({required this.order});

  @override
  Widget build(BuildContext context) {
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
              order.numOrden.substring(0, 8).toUpperCase(),
              style: AppTypography.small.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          // CLIENTE
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  order.clienteNombre,
                  style: AppTypography.body,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'CI: ${order.clienteCi}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          // PRODUCTO
          Expanded(
            flex: 3,
            child: Text(
              order.producto,
              style: AppTypography.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // CANTIDAD
          Expanded(
            flex: 1,
            child: Text('${order.cantidad} un.', style: AppTypography.small),
          ),
          // ENTREGA
          Expanded(
            flex: 2,
            child: Text(
              '${order.fechaEntrega.day}/${order.fechaEntrega.month}/${order.fechaEntrega.year}',
              style: AppTypography.small,
            ),
          ),
          // ESTADO (Doble badge)
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusBadge(status: order.estadoOrden),
                const SizedBox(height: 4),
                _PagoBadge(pago: order.estadoPago),
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
                // Un botón de menú genérico para "Acciones" (Editar, Imprimir, Eliminar)
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
  final List<OrderMock> orders;

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

// ══════════════════════════════════════════════════════════════════════════════
// TARJETA MÓVIL
// ══════════════════════════════════════════════════════════════════════════════

class _OrderCard extends StatelessWidget {
  final OrderMock order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
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
                order.numOrden.substring(0, 8).toUpperCase(),
                style: AppTypography.small.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  _PagoBadge(pago: order.estadoPago),
                  const SizedBox(width: 4),
                  _StatusBadge(status: order.estadoOrden),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Cliente
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
                  order.clienteNombre,
                  style: AppTypography.body,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Producto y Cantidad
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
                  '${order.producto} (x${order.cantidad})',
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
// BADGES (ESTADOS)
// ══════════════════════════════════════════════════════════════════════════════

// --- BADGE DE ESTADO DE PRODUCCIÓN ---
class _StatusBadge extends StatelessWidget {
  final EstadoOrden status; // Ahora usa el enum correcto
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.neutral500;
    String label = status.name.toUpperCase();
    switch (status) {
      case EstadoOrden.pendiente:
        color = AppColors.warning;
        break;
      case EstadoOrden.produccion:
        color = AppColors.info;
        break;
      case EstadoOrden.entregado:
        color = AppColors.success;
        break;
      case EstadoOrden.cancelado:
        color = AppColors.error;
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

// --- BADGE DE ESTADO DE PAGO (NUEVO) ---
class _PagoBadge extends StatelessWidget {
  final EstadoPago pago;
  const _PagoBadge({required this.pago});

  @override
  Widget build(BuildContext context) {
    Color color = AppColors.neutral500;
    String label = pago.name.toUpperCase();

    switch (pago) {
      case EstadoPago.pendiente:
        color = AppColors.error; // Rojo si no han pagado nada
        break;
      case EstadoPago.parcial:
        color = AppColors.warning; // Naranja si dejaron seña/adelanto
        break;
      case EstadoPago.pagado:
        color = AppColors.success; // Verde si está liquidado
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        // Este tiene borde en lugar de fondo para que no compita visualmente con el estado de la orden
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

// --- BOTÓN CARGAR MÁS (Tu módulo exacto) ---
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
