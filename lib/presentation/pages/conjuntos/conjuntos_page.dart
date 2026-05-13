import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // NECESARIO para detectar la tecla ESC
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import '../../widgets/shared/sticky_topbar.dart';
import '../../widgets/shared/filter_chips.dart';
import '../../widgets/shared/pagination.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/users/kpi_card.dart';

import '../../../domain/models/conjunto_model.dart';
import '../../widgets/conjunto_row.dart';
import '../../components/conjuntos/conjunto_detalle_dialog.dart';
import '../../components/conjuntos/conjunto_form_dialog.dart';

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

  // Función envoltorio para cerrar con ESC
  void _mostrarDialogoConEsc(Widget dialog) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CallbackShortcuts(
        bindings: <ShortcutActivator, VoidCallback>{
          const SingleActivator(LogicalKeyboardKey.escape): () => Navigator.pop(context),
        },
        child: Focus(
          autofocus: true,
          child: dialog,
        ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        title: Text('¿Eliminar Conjunto?', style: AppTypography.h3),
        content: Text('¿Estás seguro de eliminar "${conjunto.nombre}"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700, elevation: 0),
            onPressed: () {
              // TODO: BACKEND - Lógica para eliminar el conjunto
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"${conjunto.nombre}" eliminado'), backgroundColor: AppColors.primary500)
              );
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────── BUILD ──

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < _mobileBreakpoint;
        
        // TODO: BACKEND - Cambiar por ref.watch(conjuntosProvider)
        final List<ConjuntoModel> conjuntosMock = [
          ConjuntoModel(
            id: '1',
            nombre: 'Uniforme Escolar A',
            descripcion: 'Combo Primaria',
            precio: 120.0,
            activo: true,
            fechaCreacion: DateTime.now(),
            plantillas: [],
          ),
        ];

        final filteredConjuntos = _aplicarBusquedaYFiltro(conjuntosMock);

        return _buildListado(
          isMobile: isMobile,
          filteredConjuntos: filteredConjuntos,
          allConjuntos: conjuntosMock,
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
    final totalPages = totalItems == 0 ? 1 : (totalItems / _itemsPerPage).ceil();

    final paginatedConjuntos = isMobile
        ? filteredConjuntos.take(_currentPage * _itemsPerPage).toList()
        : filteredConjuntos
            .skip((_currentPage - 1) * _itemsPerPage)
            .take(_itemsPerPage)
            .toList();

    final activosCount = allConjuntos.where((c) => c.activo).length;
    final inactivosCount = allConjuntos.where((c) => !c.activo).length;

    return Column(
      children: [
        StickyTopbar(
          isMobile: isMobile,
          title: 'Conjuntos',
          searchHint: 'Buscar por nombre o descripción...',
          searchController: _searchController,
          onSearchChanged: (_) => setState(() => _currentPage = 1),
          newButtonLabelMobile: 'Nuevo',
          newButtonLabelDesktop: 'Nuevo conjunto',
          onNewPressed: _abrirCrear,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _KpiRow(isMobile: isMobile, allConjuntos: allConjuntos),
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
                  )
                else
                  _DesktopTable(
                    conjuntos: paginatedConjuntos,
                    onView: _abrirDetalle,
                    onEdit: _abrirEditar,
                    onDelete: _confirmarEliminacion, // CONECTADO AQUÍ
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
                    onPageChanged: (page) => setState(() => _currentPage = page),
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
  const _KpiRow({required this.isMobile, required this.allConjuntos});
  final bool isMobile;
  final List<ConjuntoModel> allConjuntos;

  @override
  Widget build(BuildContext context) {
    final total = allConjuntos.length;
    final activos = allConjuntos.where((c) => c.activo).length;
    
    final kpis = [
      KpiCard(value: '$total', label: 'Total conjuntos', description: 'Registrados'),
      KpiCard(value: '$activos', label: 'Activos', description: 'En catálogo', valueColor: AppColors.success),
      const KpiCard(value: '15', label: 'Nuevos este mes', description: 'Tendencia', valueColor: AppColors.info),
      const KpiCard(value: 'Bs. 145.0', label: 'Precio promedio', description: 'Estimado', valueColor: AppColors.warning),
    ];

    if (isMobile) {
      return Column(
        children: [
          Row(children: [Expanded(child: kpis[0]), const SizedBox(width: AppSpacing.sm), Expanded(child: kpis[1])]),
          const SizedBox(height: AppSpacing.sm),
          Row(children: [Expanded(child: kpis[2]), const SizedBox(width: AppSpacing.sm), Expanded(child: kpis[3])]),
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
    required this.onDelete, // REQUERIDO AHORA
  });

  final List<ConjuntoModel> conjuntos;
  final void Function(ConjuntoModel) onView;
  final void Function(ConjuntoModel) onEdit;
  final void Function(ConjuntoModel) onDelete; // DEFINIDO

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
              onDelete: () => onDelete(conjuntos[i]), // PASADO AL WIDGET HIJO
            ),
            if (i < conjuntos.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  Widget _col(String label, int flex) => Expanded(
    flex: flex,
    child: Text(label, style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600, color: AppColors.textMuted)),
  );
}

// ────────────────────────────────────────────────────────── MOBILE LIST ──

class _MobileList extends StatelessWidget {
  const _MobileList({required this.conjuntos, required this.onView, required this.onEdit});
  final List<ConjuntoModel> conjuntos;
  final void Function(ConjuntoModel) onView;
  final void Function(ConjuntoModel) onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var conjunto in conjuntos)
          Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            child: ListTile(
              title: Text(conjunto.nombre),
              subtitle: Text('${conjunto.precio} Bs.'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => onView(conjunto),
            ),
          ),
      ],
    );
  }
}