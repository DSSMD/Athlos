// ============================================================================
// lib/presentation/pages/admin/plantillas_page.dart
// ============================================================================
// Pantalla del módulo Diseño de Prendas — Vista 1 (listado de plantillas).
// - Header: StickyTopbar con buscador + botón "Nueva plantilla"
// - 4 KPIs: Total, Activas, Inactivas, Tipos distintos
// - FilterChips: Todas / Activas / Inactivas
// - Desktop: tabla con columnas Nombre / Tipo / Versión / Estado / Acciones
// - Mobile: cards apiladas con la misma información
// - Paginación: DesktopPagination (desktop) / LoadMoreButton (mobile)
// - Acciones:
//     * "+ Nueva plantilla" / "Editar" → abren PlantillaFormPage en modo
//       crear/editar (form multi-paso real).
//     * "Desactivar/Activar" → confirm dialog + toggle real vía provider.
//
// Catálogos: la columna "Tipo prenda" resuelve `nombreTipoPrenda` contra el
// catálogo cargado vía `tiposPrendaProvider`. Si el tipo fue eliminado de la
// BD, muestra "Tipo no disponible" (helper del modelo).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/models/plantilla_model.dart';
import '../../../../domain/models/tipo_prenda_model.dart';
import '../../../providers/catalogos_provider.dart';
import '../../../providers/plantilla_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

import '../../../widgets/shared/empty_state.dart';
import '../../../widgets/shared/filter_chips.dart';
import '../../../widgets/shared/pagination.dart';
import '../../../widgets/shared/sticky_topbar.dart';
import '../../../widgets/shared/mobile_screen_header.dart';
import '../../../widgets/shared/compact_new_button.dart';
import '../../../widgets/shared/search_input.dart';
import '../../../widgets/users/kpi_card.dart';

import 'widgets/plantilla_form_page.dart';

class PlantillasPage extends ConsumerStatefulWidget {
  const PlantillasPage({super.key});

  @override
  ConsumerState<PlantillasPage> createState() => _PlantillasPageState();
}

class _PlantillasPageState extends ConsumerState<PlantillasPage> {
  static const double _mobileBreakpoint = 900;
  static const int _itemsPerPage = 10;

  final TextEditingController _searchController = TextEditingController();

  int _currentPage = 1;

  // Filter chips: 0=Todas, 1=Activas, 2=Inactivas
  int _selectedFilter = 0;

  // Guard contra doble-click rápido en el lápiz Editar. Mientras una
  // edición está en curso (cargando plantilla completa + modal abierto),
  // los botones se deshabilitan visualmente para evitar abrir varios
  // modales superpuestos.
  bool _abriendoEditor = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── BUSQUEDA + FILTRO ─────────────────────────────────────────────────────

  /// Aplica filter chip + búsqueda local. La búsqueda matchea por nombre de
  /// plantilla o por nombre del tipo (resuelto via catálogo).
  List<PlantillaModel> _aplicarBusquedaYFiltro(
    List<PlantillaModel> all,
    List<TipoPrendaModel> tiposPrenda,
  ) {
    var resultado = all;

    switch (_selectedFilter) {
      case 1: // Activas
        resultado = resultado.where((p) => p.activa).toList();
        break;
      case 2: // Inactivas
        resultado = resultado.where((p) => !p.activa).toList();
        break;
      // case 0: Todas → sin filtro extra
    }

    final query = _searchController.text.toLowerCase().trim();
    if (query.isEmpty) return resultado;
    return resultado.where((p) {
      final nombreTipo = p.nombreTipoPrenda(tiposPrenda).toLowerCase();
      return p.nombre.toLowerCase().contains(query) ||
          nombreTipo.contains(query);
    }).toList();
  }

  // ─── ACCIONES ──────────────────────────────────────────────────────────────

  void _abrirNueva() {
    showPlantillaFormPage(context, mode: 'crear');
  }

  /// Carga la plantilla completa (medidas + materiales desde tablas hijas)
  /// y abre el form en modo editar. La plantilla de la lista solo tiene los
  /// campos planos de `plantilla_prenda` — sin esa carga, el form abriría
  /// con medidas y materiales vacíos aunque la BD los tenga.
  ///
  /// Guardado por `_abriendoEditor`: si el usuario hace doble-click rápido
  /// en el lápiz, la segunda invocación retorna inmediato sin disparar otra
  /// carga ni abrir otro modal.
  Future<void> _onEditar(PlantillaModel p) async {
    if (_abriendoEditor) return;
    setState(() => _abriendoEditor = true);
    try {
      final completa = await ref
          .read(plantillaProvider.notifier)
          .obtenerPlantillaCompleta(p.id);
      if (!mounted) return;
      await showPlantillaFormPage(
        context,
        mode: 'editar',
        initialPlantilla: completa,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar plantilla: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _abriendoEditor = false);
    }
  }

  Future<void> _onToggleActiva(PlantillaModel p) async {
    final confirm = await _confirmarToggle(context, p);
    if (confirm != true) return;
    if (!mounted) return;

    try {
      await ref.read(plantillaProvider.notifier).toggleActiva(p.id);
      if (!mounted) return;
      final mensaje = p.activa
          ? 'Plantilla "${p.nombre}" desactivada'
          : 'Plantilla "${p.nombre}" activada';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje), duration: const Duration(seconds: 2)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Diálogo de confirmación con texto contextual al estado actual.
  Future<bool?> _confirmarToggle(BuildContext context, PlantillaModel p) {
    final mensaje = p.activa
        ? '¿Desactivar plantilla "${p.nombre}"? '
              'No aparecerá en uso pero seguirá registrada.'
        : '¿Activar plantilla "${p.nombre}"? '
              'Volverá a estar disponible para uso.';
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(p.activa ? 'Desactivar plantilla' : 'Activar plantilla'),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < _mobileBreakpoint;
        final plantillasAsync = ref.watch(plantillaProvider);
        final tiposPrendaAsync = ref.watch(tiposPrendaProvider);

        // Estado combinado: necesitamos AMBOS cargados para renderizar la
        // tabla con el nombre del tipo. Si alguno está loading → loading.
        // Si alguno tiene error → mostramos error con detalle.
        if (plantillasAsync.isLoading || tiposPrendaAsync.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (plantillasAsync.hasError) {
          return Center(
            child: Text('Error al cargar plantillas: ${plantillasAsync.error}'),
          );
        }
        if (tiposPrendaAsync.hasError) {
          return Center(
            child: Text(
              'Error al cargar tipos de prenda: ${tiposPrendaAsync.error}',
            ),
          );
        }

        final all = plantillasAsync.value ?? const <PlantillaModel>[];
        final tiposPrenda = tiposPrendaAsync.value ?? const <TipoPrendaModel>[];
        final filtered = _aplicarBusquedaYFiltro(all, tiposPrenda);
        return _buildListado(
          isMobile: isMobile,
          filtered: filtered,
          all: all,
          tiposPrenda: tiposPrenda,
        );
      },
    );
  }

  // ─── LISTADO ───────────────────────────────────────────────────────────────

  Widget _buildListado({
    required bool isMobile,
    required List<PlantillaModel> filtered,
    required List<PlantillaModel> all,
    required List<TipoPrendaModel> tiposPrenda,
  }) {
    final totalItems = filtered.length;
    final totalPages = totalItems == 0
        ? 1
        : (totalItems / _itemsPerPage).ceil();
    if (_currentPage > totalPages) _currentPage = 1;

    final paginated = isMobile
        ? filtered.take(_currentPage * _itemsPerPage).toList()
        : filtered
              .skip((_currentPage - 1) * _itemsPerPage)
              .take(_itemsPerPage)
              .toList();

    final activasCount = all.where((p) => p.activa).length;
    final inactivasCount = all.length - activasCount;

    return Column(
      children: [
        if (isMobile)
          MobileScreenHeader(
            title: 'Plantillas',
            trailing: CompactNewButton(
              label: 'Nueva',
              onPressed: _abrirNueva,
            ),
            bottom: SearchInput(
              hintText: 'Buscar por nombre o tipo...',
              controller: _searchController,
              onChanged: (_) => setState(() => _currentPage = 1),
            ),
          )
        else
          StickyTopbar(
            title: 'Plantillas',
            searchHint: 'Buscar por nombre o tipo de prenda...',
            searchController: _searchController,
            onSearchChanged: (_) => setState(() => _currentPage = 1),
            newButtonLabelDesktop: 'Nueva plantilla',
            onNewPressed: _abrirNueva,
          ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _KpiRow(isMobile: isMobile),
                const SizedBox(height: AppSpacing.xl),
                FilterChips(
                  labels: const ['Todas', 'Activas', 'Inactivas'],
                  counts: [all.length, activasCount, inactivasCount],
                  selected: _selectedFilter,
                  onChanged: (i) => setState(() {
                    _selectedFilter = i;
                    _currentPage = 1;
                  }),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (paginated.isEmpty)
                  EmptyState(
                    icon: Icons.search_off,
                    title: all.isEmpty
                        ? 'No hay plantillas registradas'
                        : 'No se encontraron plantillas',
                    subtitle: all.isEmpty
                        ? 'Crea la primera con "Nueva plantilla".'
                        : 'Probá con otro filtro o crea una plantilla nueva.',
                  )
                else if (isMobile)
                  _MobileList(
                    plantillas: paginated,
                    tiposPrenda: tiposPrenda,
                    onEditar: _onEditar,
                    onToggleActiva: _onToggleActiva,
                    accionesDeshabilitadas: _abriendoEditor,
                  )
                else
                  _DesktopTable(
                    plantillas: paginated,
                    tiposPrenda: tiposPrenda,
                    onEditar: _onEditar,
                    onToggleActiva: _onToggleActiva,
                    accionesDeshabilitadas: _abriendoEditor,
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
                    recordsLabel: 'plantillas',
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// KPI ROW — 4 tarjetas
// ════════════════════════════════════════════════════════════════════════════

class _KpiRow extends ConsumerWidget {
  const _KpiRow({required this.isMobile});

  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpis = ref.watch(plantillaKpisProvider);

    final cards = [
      KpiCard(
        value: '${kpis.total}',
        label: 'Total',
        description: 'Plantillas registradas',
      ),
      KpiCard(
        value: '${kpis.activas}',
        label: 'Activas',
        description: 'En uso',
        valueColor: AppColors.success,
      ),
      KpiCard(
        value: '${kpis.inactivas}',
        label: 'Inactivas',
        description: 'Pausadas',
        valueColor: AppColors.error,
      ),
      KpiCard(
        value: '${kpis.tiposDistintos}',
        label: 'Tipos distintos',
        description: 'Categorías de prenda',
        valueColor: AppColors.info,
      ),
    ];

    if (isMobile) {
      // Grilla 2x2 en mobile (consistente con el resto del proyecto)
      return Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: cards[1]),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[2]),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: cards[3]),
              ],
            ),
          ),
        ],
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

// ════════════════════════════════════════════════════════════════════════════
// DESKTOP TABLE
// ════════════════════════════════════════════════════════════════════════════

class _DesktopTable extends StatelessWidget {
  const _DesktopTable({
    required this.plantillas,
    required this.tiposPrenda,
    required this.onEditar,
    required this.onToggleActiva,
    required this.accionesDeshabilitadas,
  });

  final List<PlantillaModel> plantillas;
  final List<TipoPrendaModel> tiposPrenda;
  final void Function(PlantillaModel) onEditar;
  final void Function(PlantillaModel) onToggleActiva;
  final bool accionesDeshabilitadas;

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
          // Header de columnas
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
                _HeaderCol('NOMBRE PRENDA', flex: 4),
                _HeaderCol('TIPO PRENDA', flex: 2),
                _HeaderCol('VERSIÓN', flex: 1),
                _HeaderCol('ESTADO', flex: 2),
                _HeaderCol('ACCIONES', flex: 2, align: TextAlign.right),
              ],
            ),
          ),
          for (var i = 0; i < plantillas.length; i++) ...[
            _DesktopRow(
              plantilla: plantillas[i],
              tiposPrenda: tiposPrenda,
              onEditar: accionesDeshabilitadas
                  ? null
                  : () => onEditar(plantillas[i]),
              onToggleActiva: accionesDeshabilitadas
                  ? null
                  : () => onToggleActiva(plantillas[i]),
            ),
            if (i < plantillas.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

class _HeaderCol extends StatelessWidget {
  const _HeaderCol(
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
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _DesktopRow extends StatelessWidget {
  const _DesktopRow({
    required this.plantilla,
    required this.tiposPrenda,
    required this.onEditar,
    required this.onToggleActiva,
  });

  final PlantillaModel plantilla;
  final List<TipoPrendaModel> tiposPrenda;
  final VoidCallback? onEditar;
  final VoidCallback? onToggleActiva;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // Nombre
          Expanded(
            flex: 4,
            child: Text(
              plantilla.nombre,
              style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Tipo (badge resuelto desde catálogo)
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _TipoBadge(label: plantilla.nombreTipoPrenda(tiposPrenda)),
            ),
          ),
          // Versión (monospace, "vN")
          Expanded(
            flex: 1,
            child: Text(
              plantilla.versionLabel,
              style: AppTypography.small.copyWith(
                fontFamily: 'monospace',
                color: AppColors.textSecondary,
              ),
            ),
          ),
          // Estado (dot + texto)
          Expanded(flex: 2, child: _EstadoIndicator(activa: plantilla.activa)),
          // Acciones
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                tooltip: 'Acciones',
                onSelected: (value) {
                  if (value == 'editar' && onEditar != null) onEditar!();
                  if (value == 'estado' && onToggleActiva != null) onToggleActiva!();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'estado',
                    child: Row(
                      children: [
                        Icon(
                          plantilla.activa ? Icons.block : Icons.check_circle_outline,
                          size: 18,
                          color: plantilla.activa ? AppColors.error : AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          plantilla.activa ? 'Desactivar' : 'Activar',
                          style: TextStyle(
                            color: plantilla.activa ? AppColors.error : AppColors.success,
                          ),
                        ),
                      ],
                    ),
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

// ════════════════════════════════════════════════════════════════════════════
// MOBILE LIST
// ════════════════════════════════════════════════════════════════════════════

class _MobileList extends StatelessWidget {
  const _MobileList({
    required this.plantillas,
    required this.tiposPrenda,
    required this.onEditar,
    required this.onToggleActiva,
    required this.accionesDeshabilitadas,
  });

  final List<PlantillaModel> plantillas;
  final List<TipoPrendaModel> tiposPrenda;
  final void Function(PlantillaModel) onEditar;
  final void Function(PlantillaModel) onToggleActiva;
  final bool accionesDeshabilitadas;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < plantillas.length; i++) ...[
          _MobileCard(
            plantilla: plantillas[i],
            tiposPrenda: tiposPrenda,
            onEditar: accionesDeshabilitadas
                ? null
                : () => onEditar(plantillas[i]),
            onToggleActiva: accionesDeshabilitadas
                ? null
                : () => onToggleActiva(plantillas[i]),
          ),
          if (i < plantillas.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _MobileCard extends StatelessWidget {
  const _MobileCard({
    required this.plantilla,
    required this.tiposPrenda,
    required this.onEditar,
    required this.onToggleActiva,
  });

  final PlantillaModel plantilla;
  final List<TipoPrendaModel> tiposPrenda;
  final VoidCallback? onEditar;
  final VoidCallback? onToggleActiva;

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
            children: [
              Expanded(
                child: Text(
                  plantilla.nombre,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                plantilla.versionLabel,
                style: AppTypography.small.copyWith(
                  fontFamily: 'monospace',
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _TipoBadge(label: plantilla.nombreTipoPrenda(tiposPrenda)),
              const SizedBox(width: AppSpacing.md),
              _EstadoIndicator(activa: plantilla.activa),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                tooltip: 'Acciones',
                onSelected: (value) {
                  if (value == 'editar' && onEditar != null) onEditar!();
                  if (value == 'estado' && onToggleActiva != null) onToggleActiva!();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'estado',
                    child: Row(
                      children: [
                        Icon(
                          plantilla.activa ? Icons.block : Icons.check_circle_outline,
                          size: 18,
                          color: plantilla.activa ? AppColors.error : AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          plantilla.activa ? 'Desactivar' : 'Activar',
                          style: TextStyle(
                            color: plantilla.activa ? AppColors.error : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// BADGES / INDICATORS
// ════════════════════════════════════════════════════════════════════════════

// DECISIÓN: badge de tipo con un solo color (info). RAZÓN: los tipos de
// prenda son volátiles (catálogo dinámico). No tiene sentido mapear color
// por enum value que ya no existe. CAMBIAR: si el equipo quiere colores
// por tipo, agregar columna `color_hex` a tipo_prenda y leerla del catálogo.
class _TipoBadge extends StatelessWidget {
  const _TipoBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    const color = AppColors.info;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _EstadoIndicator extends StatelessWidget {
  const _EstadoIndicator({required this.activa});
  final bool activa;

  @override
  Widget build(BuildContext context) {
    final color = activa ? AppColors.success : AppColors.textMuted;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          activa ? 'Activa' : 'Inactiva',
          style: AppTypography.small.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
