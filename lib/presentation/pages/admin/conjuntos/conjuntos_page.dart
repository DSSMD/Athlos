// lib/presentation/pages/admin/conjuntos/conjuntos_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

import '../../../widgets/shared/sticky_topbar.dart';
import '../../../widgets/shared/filter_chips.dart';
import '../../../widgets/shared/pagination.dart';
import '../../../widgets/shared/empty_state.dart';
import '../../../widgets/shared/mobile_screen_header.dart';
import '../../../widgets/shared/compact_new_button.dart';
import '../../../widgets/shared/search_input.dart';
import '../../../widgets/users/kpi_card.dart';

import 'widgets/conjunto_row.dart';
import 'widgets/conjunto_detalle_dialog.dart';
import 'widgets/conjunto_form_dialog.dart';

import '../../../../domain/models/conjunto_model.dart';
import '../../../../presentation/providers/conjunto_provider.dart';

class ConjuntosPage extends ConsumerStatefulWidget {
  const ConjuntosPage({super.key});

  @override
  ConsumerState<ConjuntosPage> createState() => _ConjuntosPageState();
}

class _ConjuntosPageState extends ConsumerState<ConjuntosPage> {
  static const double _mobileBreakpoint = 900;
  final TextEditingController _searchController = TextEditingController();

  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  int _selectedFilter = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────── BÚSQUEDA + FILTRO ──

  List<ConjuntoModel> _aplicarBusquedaYFiltro(List<ConjuntoModel> all) {
    var resultado = all;

    if (_selectedFilter == 1) {
      resultado = resultado.where((c) => c.activo).toList();
    } else if (_selectedFilter == 2) {
      resultado = resultado.where((c) => !c.activo).toList();
    }

    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return resultado;

    return resultado.where((c) {
      return c.nombre.toLowerCase().contains(query) ||
          c.descripcion.toLowerCase().contains(query);
    }).toList();
  }

  // ─────────────────────────────────────────────────────────── ACCIONES ──

  void _mostrarDialogoConEsc(Widget dialog) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.pop(context),
        },
        child: Focus(autofocus: true, child: dialog),
      ),
    );
  }

  void _abrirCrear() {
    _mostrarDialogoConEsc(const ConjuntoFormDialog());
  }

  void _abrirEditar(ConjuntoModel conjunto) {
    _mostrarDialogoConEsc(ConjuntoFormDialog(conjunto: conjunto));
  }

  void _abrirDetalle(ConjuntoModel conjunto) {
    showDialog(
      context: context,
      builder: (context) => ConjuntoDetalleDialog(conjunto: conjunto),
    );
  }

  void _confirmarEliminacion(ConjuntoModel conjunto) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        title: Text('¿Eliminar Conjunto?', style: AppTypography.h3),
        content: Text(
          '¿Estás seguro de eliminar "${conjunto.nombre}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary500),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(context);
              try {
                await ref
                    .read(conjuntoProvider.notifier)
                    .eliminarConjunto(conjunto.id);
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('"${conjunto.nombre}" eliminado'),
                    backgroundColor: AppColors.primary500,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Error al eliminar: $e'),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────── BUILD ──

  @override
  Widget build(BuildContext context) {
    final asyncConjuntos = ref.watch(conjuntoProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < _mobileBreakpoint;

        return asyncConjuntos.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: AppSpacing.md),
                Text('Error al cargar conjuntos', style: AppTypography.h3),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  error.toString(),
                  style: AppTypography.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: () =>
                      ref.read(conjuntoProvider.notifier).refresh(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
          data: (allConjuntos) {
            final filteredConjuntos = _aplicarBusquedaYFiltro(allConjuntos);
            return _buildListado(
              isMobile: isMobile,
              filteredConjuntos: filteredConjuntos,
              allConjuntos: allConjuntos,
            );
          },
        );
      },
    );
  }

  Widget _buildListado({
    required bool isMobile,
    required List<ConjuntoModel> filteredConjuntos,
    required List<ConjuntoModel> allConjuntos,
  }) {
    final totalItems = filteredConjuntos.length;
    final totalPages = totalItems == 0
        ? 1
        : (totalItems / _itemsPerPage).ceil();

    final paginatedConjuntos = isMobile
        ? filteredConjuntos.take(_currentPage * _itemsPerPage).toList()
        : filteredConjuntos
              .skip((_currentPage - 1) * _itemsPerPage)
              .take(_itemsPerPage)
              .toList();

    final activosCount = allConjuntos.where((c) => c.activo).length;
    final inactivosCount = allConjuntos.where((c) => !c.activo).length;

    // Precio promedio calculado dinámicamente
    final precioPromedio = allConjuntos.isEmpty
        ? 0.0
        : allConjuntos.fold<double>(0.0, (sum, c) => sum + c.precioTotal) /
              allConjuntos.length;

    return Column(
      children: [
        if (isMobile)
          MobileScreenHeader(
            title: 'Conjuntos',
            trailing: CompactNewButton(label: 'Nuevo', onPressed: _abrirCrear),
            bottom: SearchInput(
              hintText: 'Buscar conjunto...',
              controller: _searchController,
              onChanged: (_) => setState(() => _currentPage = 1),
            ),
          )
        else
          StickyTopbar(
            title: 'Conjuntos',
            searchHint: 'Buscar por nombre o descripción...',
            searchController: _searchController,
            onSearchChanged: (_) => setState(() => _currentPage = 1),
            newButtonLabelDesktop: 'Nuevo conjunto',
            onNewPressed: _abrirCrear,
            newButtonColor: AppColors.primary500,
            newTextColor: Colors.white,
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _KpiRow(
                  isMobile: isMobile,
                  allConjuntos: allConjuntos,
                  precioPromedio: precioPromedio,
                ),
                const SizedBox(height: AppSpacing.xl),

                FilterChips(
                  labels: const ['Todos', 'Activos', 'Inactivos'],
                  counts: [allConjuntos.length, activosCount, inactivosCount],
                  selected: _selectedFilter,
                  onChanged: (i) => setState(() {
                    _selectedFilter = i;
                    _currentPage = 1;
                  }),
                ),

                const SizedBox(height: AppSpacing.lg),

                if (paginatedConjuntos.isEmpty)
                  const EmptyState(
                    icon: Icons.search_off,
                    title: 'No se encontraron conjuntos',
                    subtitle: 'Probá con otro filtro o crea uno nuevo.',
                  )
                else if (isMobile)
                  _MobileList(
                    conjuntos: paginatedConjuntos,
                    onView: _abrirDetalle,
                    onEdit: _abrirEditar,
                    onDelete: _confirmarEliminacion,
                  )
                else
                  _DesktopTable(
                    conjuntos: paginatedConjuntos,
                    onView: _abrirDetalle,
                    onEdit: _abrirEditar,
                    onDelete: _confirmarEliminacion,
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
                    recordsLabel: 'conjuntos',
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────── KPI ROW ──

class _KpiRow extends StatelessWidget {
  const _KpiRow({
    required this.isMobile,
    required this.allConjuntos,
    required this.precioPromedio,
  });
  final bool isMobile;
  final List<ConjuntoModel> allConjuntos;
  final double precioPromedio;

  @override
  Widget build(BuildContext context) {
    final total = allConjuntos.length;
    final activos = allConjuntos.where((c) => c.activo).length;

    final kpis = [
      KpiCard(
        value: '$total',
        label: 'Total conjuntos',
        description: 'Registrados',
      ),
      KpiCard(
        value: '$activos',
        label: 'Activos',
        description: 'En catálogo',
        valueColor: AppColors.success,
      ),
      KpiCard(
        value:
            '${allConjuntos.fold<int>(0, (sum, c) => sum + c.plantillas.length)}',
        label: 'Plantillas totales',
        description: 'En todos los conjuntos',
        valueColor: AppColors.info,
      ),
      KpiCard(
        value: 'Bs. ${precioPromedio.toStringAsFixed(2)}',
        label: 'Precio promedio',
        description: 'Calculado automático',
        valueColor: AppColors.warning,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: kpis[0]),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: kpis[1]),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: kpis[2]),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: kpis[3]),
            ],
          ),
        ],
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

// ───────────────────────────────────────────────────────── DESKTOP TABLE ──

class _DesktopTable extends StatelessWidget {
  const _DesktopTable({
    required this.conjuntos,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final List<ConjuntoModel> conjuntos;
  final void Function(ConjuntoModel) onView;
  final void Function(ConjuntoModel) onEdit;
  final void Function(ConjuntoModel) onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.brandWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                _col('NOMBRE / DESCRIPCIÓN', 4),
                _col('PRECIO', 2),
                _col('PLANTILLAS', 2),
                _col('ESTADO', 2),
                _col('ACCIONES', 1),
                const SizedBox(width: 60),
              ],
            ),
          ),
          const Divider(height: 1),
          for (var i = 0; i < conjuntos.length; i++) ...[
            ConjuntoRow(
              conjunto: conjuntos[i],
              onView: () => onView(conjuntos[i]),
              onEdit: () => onEdit(conjuntos[i]),
              onDelete: () => onDelete(conjuntos[i]),
            ),
            if (i < conjuntos.length - 1) const Divider(height: 1),
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
      ),
    ),
  );
}

// ────────────────────────────────────────────────────────── MOBILE LIST ──

class _MobileList extends StatelessWidget {
  const _MobileList({
    required this.conjuntos,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });
  final List<ConjuntoModel> conjuntos;
  final void Function(ConjuntoModel) onView;
  final void Function(ConjuntoModel) onEdit;
  final void Function(ConjuntoModel) onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var conjunto in conjuntos)
          Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ListTile(
              title: Text(
                conjunto.nombre,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                '${conjunto.precioTotal.toStringAsFixed(2)} Bs. · ${conjunto.plantillas.length} plantillas',
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  if (value == 'ver') {
                    onView(conjunto);
                  } else if (value == 'editar') {
                    onEdit(conjunto);
                  } else if (value == 'eliminar') {
                    onDelete(conjunto);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'ver',
                    child: Row(
                      children: [
                        Icon(
                          Icons.visibility_outlined,
                          size: 20,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text('Ver Detalles'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: AppColors.primary500,
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'eliminar',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 20, color: Colors.red),
                        SizedBox(width: AppSpacing.sm),
                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
              onTap: () => onView(conjunto),
            ),
          ),
      ],
    );
  }
}
