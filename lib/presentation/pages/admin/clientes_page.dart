// lib/presentation/pages/admin/clientes_page.dart

// Página principal de gestión de clientes para el admin. Contiene:
// - Header con título, buscador y botón de nuevo cliente
// - KPI card con conteo total
// - Listado de clientes en formato tabla (desktop) o cards (mobile)
// - Paginación (desktop) o botón "Cargar más" (mobile)
// - Form integrado en el mismo espacio del shell (sin navegar a otra ruta)
// El diseño es responsive y sigue el mismo patrón que usuarios_page.dart
// para mantener consistencia con el sistema Athlos.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/clientes/cliente_card.dart';
import '../../components/clientes/cliente_list_row.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import '../../widgets/users/kpi_card.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/pagination.dart';
import '../../widgets/shared/sticky_topbar.dart';

import '../../../domain/models/cliente_model.dart';
import '../../providers/cliente_provider.dart';

import '../../models/cliente_mock.dart' show ClienteFormMode;
import 'cliente_form_page.dart';

/// Modo de vista interno de la página de clientes.
/// Permite alternar entre listado y formulario sin cambiar de ruta,
/// preservando el sidebar del shell (MainLayout).
enum _ClientesViewMode { listado, form }

class ClientesPage extends ConsumerStatefulWidget {
  const ClientesPage({super.key});

  @override
  ConsumerState<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends ConsumerState<ClientesPage> {
  static const double _mobileBreakpoint = 900;

  _ClientesViewMode _viewMode = _ClientesViewMode.listado;

  final TextEditingController _searchController = TextEditingController();

  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ClienteModel> _getFilteredClientes(List<ClienteModel> allClientes) {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return allClientes;
    return allClientes.where((c) {
      return c.nombreCompleto.toLowerCase().contains(query) ||
          c.ciCliente.toLowerCase().contains(query) ||
          (c.numTelefono?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _abrirCrear() {
    setState(() {
      _viewMode = _ClientesViewMode.form;
    });
  }

  // TODO: El form actual (cliente_form_page.dart) usa ClienteMock, no ClienteModel.
  // Cuando el backend/modelo unifique esos tipos, pasar el cliente como initialCliente
  // y cambiar el modo a editar. Por ahora abre el form vacío para no romper tipos.
  void _abrirEditar(ClienteModel cliente) {
    setState(() {
      _viewMode = _ClientesViewMode.form;
    });
  }

  void _volverAlListado() {
    setState(() {
      _viewMode = _ClientesViewMode.listado;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < _mobileBreakpoint;

        // Cuando está en modo formulario, renderizamos el form dentro del shell
        // con un header que permite volver al listado, preservando el sidebar.
        if (_viewMode != _ClientesViewMode.listado) {
          return Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? AppSpacing.lg : AppSpacing.xl2,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    TextButton.icon(
                      onPressed: _volverAlListado,
                      icon: const Icon(Icons.arrow_back, size: 18),
                      label: const Text('Volver al listado'),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text('Nuevo cliente', style: AppTypography.h3),
                  ],
                ),
              ),
              const Expanded(
                child: ClienteFormPage(mode: ClienteFormMode.crear),
              ),
            ],
          );
        }

        // Modo listado: consumimos el provider
        final clientesAsync = ref.watch(clientesProvider);

        return clientesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) =>
              Center(child: Text('Error al cargar clientes: $error')),
          data: (clientesReales) {
            final filteredClientes = _getFilteredClientes(clientesReales);
            return _buildListado(
              isMobile: isMobile,
              filteredClientes: filteredClientes,
              allClientes: clientesReales,
            );
          },
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
    final clientes = filteredClientes;

    final totalItems = clientes.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();

    final paginatedClientes = isMobile
        ? clientes.take(_currentPage * _itemsPerPage).toList()
        : clientes
            .skip((_currentPage - 1) * _itemsPerPage)
            .take(_itemsPerPage)
            .toList();

    return Column(
      children: [
        StickyTopbar(
          isMobile: isMobile,
          title: 'Clientes',
          searchHint: 'Buscar por nombre, CI, teléfono...',
          searchController: _searchController,
          onSearchChanged: (_) => setState(() {
            _currentPage = 1;
          }),
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
                _KpiRow(
                  isMobile: isMobile,
                  totalClientes: allClientes.length,
                ),
                const SizedBox(height: AppSpacing.xl),

                if (clientes.isEmpty)
                  const EmptyState(
                    icon: Icons.search_off,
                    title: 'No se encontraron clientes',
                    subtitle: 'Probá con otro término de búsqueda.',
                  )
                else if (isMobile)
                  _MobileList(
                    clientes: paginatedClientes,
                    onEdit: _abrirEditar,
                  )
                else
                  _DesktopTable(
                    clientes: paginatedClientes,
                    onEdit: _abrirEditar,
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
// KPI ROW — tarjeta con conteo total de clientes
// TODO: cuando el modelo tenga campo 'activo', expandir a 2-3 KPIs
// (Total / Activos / Con deuda) como muestra el Figma.
// ══════════════════════════════════════════════════════════════════════════════

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.isMobile, required this.totalClientes});

  final bool isMobile;
  final int totalClientes;

  @override
  Widget build(BuildContext context) {
    final card = KpiCard(
      value: '$totalClientes',
      label: 'Total clientes',
      description: 'Registrados en el sistema',
    );

    if (isMobile) {
      return card;
    }
    return Row(
      children: [
        Expanded(child: card),
        const Spacer(flex: 3),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DESKTOP TABLE — header + filas
// ══════════════════════════════════════════════════════════════════════════════

class _DesktopTable extends StatelessWidget {
  const _DesktopTable({required this.clientes, required this.onEdit});

  final List<ClienteModel> clientes;
  final void Function(ClienteModel) onEdit;

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
                _col('CLIENTE', 3),
                _col('CI', 2),
                _col('TELÉFONO', 2),
                _col('DIRECCIÓN', 3),
                _col('REGISTRADO', 2),
                SizedBox(
                  width: 80,
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
          for (var i = 0; i < clientes.length; i++) ...[
            ClienteListRow(
              cliente: clientes[i],
              onEdit: () => onEdit(clientes[i]),
            ),
            if (i < clientes.length - 1)
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
// MOBILE LIST — stack vertical de cards
// ══════════════════════════════════════════════════════════════════════════════

class _MobileList extends StatelessWidget {
  const _MobileList({required this.clientes, required this.onEdit});

  final List<ClienteModel> clientes;
  final void Function(ClienteModel) onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < clientes.length; i++) ...[
          ClienteCard(
            cliente: clientes[i],
            onTap: () => onEdit(clientes[i]),
          ),
          if (i < clientes.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}