// lib/presentation/pages/admin/clientes_page.dart
// ============================================================================
// Página principal de gestión de clientes para el admin. Contiene:
// - Header con título, buscador, botón Exportar y botón Nuevo cliente
// - 4 KPIs (Total, Activos este mes, Nuevos este mes, Deuda total)
// - 4 Filter chips (Todos, Activos, Con deuda, Inactivos)
// - Listado en formato tabla (desktop) o cards (mobile)
// - Paginación (desktop) o "Cargar más" (mobile)
// - Drawer lateral para crear/editar (decisión de Den + cliente)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/clientes/cliente_form_drawer.dart';
import '../../components/clientes/cliente_card.dart';
import '../../components/clientes/cliente_list_row.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/breakpoints.dart';

import '../../widgets/users/kpi_card.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/filter_chips.dart';
import '../../widgets/shared/mobile_screen_header.dart';
import '../../widgets/shared/pagination.dart';
import '../../widgets/shared/search_input.dart';
import '../../widgets/shared/sticky_topbar.dart';

import '../../../domain/models/cliente_model.dart';
import '../../providers/cliente_provider.dart';

class ClientesPage extends ConsumerStatefulWidget {
  const ClientesPage({super.key});

  @override
  ConsumerState<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends ConsumerState<ClientesPage> {
  final TextEditingController _searchController = TextEditingController();

  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  // Filtros: 0=Todos, 1=Activos, 2=Con deuda, 3=Inactivos
  int _selectedFilter = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────── BÚSQUEDA + FILTRO ──

  /// Aplica búsqueda + filtro chip al listado completo.
  List<ClienteModel> _aplicarBusquedaYFiltro(List<ClienteModel> all) {
    var resultado = all;

    // 1. Filter chip
    switch (_selectedFilter) {
      case 1: // Activos
        resultado = resultado.where((c) => c.activo).toList();
        break;
      case 2: // Con deuda
        // TODO(SCRUM-69): cuando backend exponga deuda, filtrar por > 0.
        // Por ahora retornamos lista vacía para reflejar que no hay datos.
        resultado = [];
        break;
      case 3: // Inactivos
        resultado = resultado.where((c) => !c.activo).toList();
        break;
      // case 0: Todos → sin filtro
    }

    // 2. Búsqueda
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return resultado;

    return resultado.where((c) {
      return c.nombreMostrable.toLowerCase().contains(query) ||
          c.ciCliente.toLowerCase().contains(query) ||
          (c.email?.toLowerCase().contains(query) ?? false) ||
          (c.numTelefono?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  // ─────────────────────────────────────────────────────────── ACCIONES ──

  void _abrirCrear() {
    showClienteFormDrawer(context, mode: ClienteFormMode.crear);
  }

  // Llamada a la que se le hace click en "Ver" del listado:
  // abre el drawer directamente en el tab "Resumen" (lectura primero,
  // edición después si el usuario lo elige).
  void _abrirEditar(ClienteModel cliente) {
    showClienteFormDrawer(
      context,
      mode: ClienteFormMode.editar,
      initialCliente: cliente,
      initialTab: 1, // 1 = Resumen
    );
  }

  void _exportar() {
    // TODO(SCRUM-69): implementar exportación a Excel/CSV. Pendiente de
    // confirmación de Denshelmer sobre formato y campos a exportar.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Exportar — funcionalidad pendiente'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────── BUILD ──

  @override
  Widget build(BuildContext context) {
    // Migrated to AppBreakpoints.mobile (1100). Was previously: 900.
    final isMobile = context.isMobile;
    final clientesAsync = ref.watch(clientesProvider);

    return clientesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) =>
          Center(child: Text('Error al cargar clientes: $error')),
      data: (clientesReales) {
        final filteredClientes = _aplicarBusquedaYFiltro(clientesReales);
        return _buildListado(
          isMobile: isMobile,
          filteredClientes: filteredClientes,
          allClientes: clientesReales,
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────── LISTADO ──

  Widget _buildListado({
    required bool isMobile,
    required List<ClienteModel> filteredClientes,
    required List<ClienteModel> allClientes,
  }) {
    final totalItems = filteredClientes.length;
    final totalPages = totalItems == 0
        ? 1
        : (totalItems / _itemsPerPage).ceil();

    final paginatedClientes = isMobile
        ? filteredClientes.take(_currentPage * _itemsPerPage).toList()
        : filteredClientes
              .skip((_currentPage - 1) * _itemsPerPage)
              .take(_itemsPerPage)
              .toList();

    // Conteos para los filter chips (sobre la lista completa, no filtrada)
    final activosCount = allClientes.where((c) => c.activo).length;
    final inactivosCount = allClientes.where((c) => !c.activo).length;
    // TODO(SCRUM-69): cuando backend exponga deuda, calcular el real.
    const conDeudaCount = 0;

    return Column(
      children: [
        if (isMobile)
          MobileScreenHeader(
            title: 'Clientes',
            trailing: _CompactNewButton(label: 'Nuevo', onPressed: _abrirCrear),
          )
        else
          StickyTopbar(
            isMobile: isMobile,
            title: 'Clientes',
            searchHint: 'Buscar por nombre, NIT, teléfono...',
            searchController: _searchController,
            onSearchChanged: (_) => setState(() => _currentPage = 1),
            newButtonLabelMobile: 'Nuevo',
            newButtonLabelDesktop: 'Nuevo cliente',
            onNewPressed: _abrirCrear,
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isMobile) ...[
                  SearchInput(
                    hintText: 'Buscar por nombre, NIT, teléfono...',
                    controller: _searchController,
                    onChanged: (_) => setState(() => _currentPage = 1),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                // KPIs (4 tarjetas)
                _KpiRow(isMobile: isMobile, allClientes: allClientes),
                const SizedBox(height: AppSpacing.xl),

                // Filter chips + botón Exportar (en desktop, en una fila)
                if (isMobile) ...[
                  FilterChips(
                    labels: const [
                      'Todos',
                      'Activos',
                      'Con deuda',
                      'Inactivos',
                    ],
                    counts: [
                      allClientes.length,
                      activosCount,
                      conDeudaCount,
                      inactivosCount,
                    ],
                    selected: _selectedFilter,
                    onChanged: (i) => setState(() {
                      _selectedFilter = i;
                      _currentPage = 1;
                    }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _exportar,
                      icon: const Icon(Icons.file_download_outlined, size: 18),
                      label: const Text('Exportar'),
                    ),
                  ),
                ] else
                  Row(
                    children: [
                      Expanded(
                        child: FilterChips(
                          labels: const [
                            'Todos',
                            'Activos',
                            'Con deuda',
                            'Inactivos',
                          ],
                          counts: [
                            allClientes.length,
                            activosCount,
                            conDeudaCount,
                            inactivosCount,
                          ],
                          selected: _selectedFilter,
                          onChanged: (i) => setState(() {
                            _selectedFilter = i;
                            _currentPage = 1;
                          }),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: _exportar,
                        icon: const Icon(
                          Icons.file_download_outlined,
                          size: 18,
                        ),
                        label: const Text('Exportar'),
                      ),
                    ],
                  ),

                const SizedBox(height: AppSpacing.lg),

                if (paginatedClientes.isEmpty)
                  EmptyState(
                    icon: Icons.search_off,
                    title: _selectedFilter == 2
                        ? 'No hay clientes con deuda'
                        : 'No se encontraron clientes',
                    subtitle: _selectedFilter == 2
                        ? 'La información de deuda se mostrará cuando esté disponible.'
                        : 'Probá con otro filtro o crea un cliente nuevo.',
                  )
                else if (isMobile)
                  _MobileList(clientes: paginatedClientes, onView: _abrirEditar)
                else
                  _DesktopTable(
                    clientes: paginatedClientes,
                    onView: _abrirEditar,
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
                    recordsLabel: 'clientes',
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// KPI ROW — 4 tarjetas según Figma
// ══════════════════════════════════════════════════════════════════════════════

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.isMobile, required this.allClientes});

  final bool isMobile;
  final List<ClienteModel> allClientes;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final primerDiaMes = DateTime(now.year, now.month, 1);

    final total = allClientes.length;
    final activosEsteMes = allClientes
        .where(
          (c) =>
              c.activo &&
              c.updatedAt != null &&
              c.updatedAt!.isAfter(primerDiaMes),
        )
        .length;
    final nuevosEsteMes = allClientes
        .where((c) => c.createdAt != null && c.createdAt!.isAfter(primerDiaMes))
        .length;
    // TODO(SCRUM-69): calcular deuda real cuando backend la exponga.
    const deudaTotal = 0;

    final kpis = [
      KpiCard(
        value: '$total',
        label: 'Total clientes',
        description: 'Registrados',
      ),
      KpiCard(
        value: '$activosEsteMes',
        label: 'Activos este mes',
        description: 'Con actividad',
        valueColor: AppColors.info,
      ),
      KpiCard(
        value: '$nuevosEsteMes',
        label: 'Nuevos este mes',
        description: 'Recientes',
        valueColor: AppColors.success,
      ),
      KpiCard(
        value: 'Bs. $deudaTotal',
        label: 'Deuda total',
        description: 'Pendiente',
        valueColor: AppColors.error,
      ),
    ];

    if (isMobile) {
      // Grilla 2x2 en mobile (consistente con SCRUM-72)
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
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: kpis[2]),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: kpis[3]),
              ],
            ),
          ),
        ],
      );
    }

    // Desktop: 4 KPIs en una fila
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
  const _DesktopTable({required this.clientes, required this.onView});

  final List<ClienteModel> clientes;
  final void Function(ClienteModel) onView;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _col('CLIENTE', 4),
                _col('NIT / CI', 2),
                _col('TELÉFONO', 2),
                _col('ÓRDENES', 2, align: TextAlign.center),
                _col('TOTAL\nCOMPRADO', 2, align: TextAlign.center),
                _col('DEUDA', 1, align: TextAlign.center),
                _col('ÚLTIMO\nPEDIDO', 2, align: TextAlign.center),
                _col('ESTADO', 2),
                const SizedBox(width: 60),
              ],
            ),
          ),
          for (var i = 0; i < clientes.length; i++) ...[
            ClienteListRow(
              cliente: clientes[i],
              onView: () => onView(clientes[i]),
            ),
            if (i < clientes.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }

  Widget _col(String label, int flex, {TextAlign align = TextAlign.left}) =>
      Expanded(
        flex: flex,
        child: Text(
          label,
          textAlign: align,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// MOBILE LIST
// ══════════════════════════════════════════════════════════════════════════════

class _MobileList extends StatelessWidget {
  const _MobileList({required this.clientes, required this.onView});

  final List<ClienteModel> clientes;
  final void Function(ClienteModel) onView;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < clientes.length; i++) ...[
          ClienteCard(cliente: clientes[i], onTap: () => onView(clientes[i])),
          if (i < clientes.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// COMPACT NEW BUTTON — para el header mobile
// ══════════════════════════════════════════════════════════════════════════════

class _CompactNewButton extends StatelessWidget {
  const _CompactNewButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary500,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 16, color: AppColors.brandWhite),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.small.copyWith(
                  color: AppColors.brandWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
