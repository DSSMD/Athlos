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

// lib/presentation/pages/clientes_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../components/clientes/cliente_form_drawer.dart';
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

class ClientesPage extends ConsumerStatefulWidget {
  const ClientesPage({super.key});

  @override
  ConsumerState<ClientesPage> createState() => _ClientesPageState();
}

class _ClientesPageState extends ConsumerState<ClientesPage> {
  static const double _mobileBreakpoint = 900;

  final TextEditingController _searchController = TextEditingController();

  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 1. BUSCADOR MEJORADO: Ahora busca por Razón Social, Email, etc.
  List<ClienteModel> _getFilteredClientes(List<ClienteModel> allClientes) {
    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return allClientes;

    return allClientes.where((c) {
      return c.nombreMostrable.toLowerCase().contains(
            query,
          ) || // Usa el getter inteligente
          c.ciCliente.toLowerCase().contains(query) ||
          (c.email?.toLowerCase().contains(query) ?? false) ||
          (c.numTelefono?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  // ─────────────────────────────────────────────────────────── ACCIONES ──

  void _abrirCrear() {
    // Llamamos a la función pública del drawer
    showClienteFormDrawer(
      context,
      mode: ClienteFormMode.crear, // Usamos el Enum correcto
    );
  }

  void _abrirEditar(ClienteModel cliente) {
    // Ahora que el modelo está unificado, pasamos el cliente real
    showClienteFormDrawer(
      context,
      mode: ClienteFormMode.editar,
      initialCliente: cliente,
    );
  }

  // ─────────────────────────────────────────────────────────── BUILD PRINCIPAL ──

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < _mobileBreakpoint;

        // Consumimos el provider directamente para traer los datos reales de Supabase
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
              allClientes: clientesReales, // Pasa todos para el KPI total
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
          searchHint: 'Buscar por nombre, CI, teléfono, email...',
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
                _KpiRow(isMobile: isMobile, totalClientes: allClientes.length),
                const SizedBox(height: AppSpacing.xl),

                if (clientes.isEmpty)
                  const EmptyState(
                    icon: Icons.search_off,
                    title: 'No se encontraron clientes',
                    subtitle:
                        'Probá con otro término de búsqueda o crea uno nuevo.',
                  )
                else if (isMobile)
                  // ⚠️ Asegúrate de que _MobileList reciba List<ClienteModel>
                  _MobileList(clientes: paginatedClientes, onEdit: _abrirEditar)
                else
                  // ⚠️ Asegúrate de que _DesktopTable reciba List<ClienteModel>
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
          ClienteCard(cliente: clientes[i], onTap: () => onEdit(clientes[i])),
          if (i < clientes.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}
