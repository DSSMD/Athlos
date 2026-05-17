// lib/presentation/pages/admin/inventario/inventario_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/breakpoints.dart';
import '../../../providers/insumo_provider.dart';
import '../../../providers/movimiento_provider.dart';
import '../../../widgets/shared/mobile_screen_header.dart';
import '../../../widgets/shared/mobile_tabs_row.dart';
import '../../../widgets/shared/search_input.dart';
import 'widgets/insumo_form_modal.dart';
import 'widgets/movimiento_form_modal.dart';
import 'widgets/movimientos_tab_content.dart';
import 'widgets/stock_tab_content.dart';

class _InventarioTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int i) => state = i;
}

final _inventarioTabProvider = NotifierProvider<_InventarioTabNotifier, int>(
  _InventarioTabNotifier.new,
);

class InventarioPage extends ConsumerWidget {
  const InventarioPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Migrated to AppBreakpoints.mobile (1100). Was previously: 800.
    return context.isMobile ? _MobileLayout() : _DesktopLayout();
  }
}

// ─── MOBILE ──────────────────────────────────────────────────────────────────

class _MobileLayout extends ConsumerStatefulWidget {
  @override
  ConsumerState<_MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends ConsumerState<_MobileLayout> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    final tab = ref.read(_inventarioTabProvider);
    final initialQuery = tab == 0
        ? ref.read(inventarioFiltrosProvider).query
        : ref.read(movimientoFiltrosProvider).query;
    _searchCtrl = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Al cambiar de tab limpia tanto el controller del buscador como las
  /// queries en ambos providers, para que no queden filtros invisibles.
  /// Mismo patrón que `_DesktopLayoutState._onTabChange`.
  void _onTabChange(int newTab) {
    final current = ref.read(_inventarioTabProvider);
    if (current == newTab) return;
    _searchCtrl.clear();
    ref.read(inventarioFiltrosProvider.notifier).setQuery('');
    ref.read(movimientoFiltrosProvider.notifier).setQuery('');
    ref.read(_inventarioTabProvider.notifier).set(newTab);
  }

  /// El buscador escribe al provider de filtros correspondiente al tab
  /// activo. Stock y Movimientos tienen estados de filtros separados,
  /// no se contaminan entre sí.
  void _onSearchChanged(String v) {
    final tab = ref.read(_inventarioTabProvider);
    if (tab == 0) {
      ref.read(inventarioFiltrosProvider.notifier).setQuery(v);
    } else {
      ref.read(movimientoFiltrosProvider.notifier).setQuery(v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(_inventarioTabProvider);
    final isStock = tab == 0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          MobileScreenHeader(
            title: 'Inventario',
            // El bottom slot del header oscuro lleva 3 niveles en un Column:
            // tabs Stock/Movimientos, espacio, y el SearchInput. Todo queda
            // dentro del bloque oscuro (sidebarDark) — mismo patrón que
            // StickyTopbar mobile en las otras pantallas.
            bottom: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MobileTabsRow(
                  labels: const ['Stock', 'Movimientos'],
                  selectedIndex: tab,
                  onTap: _onTabChange,
                ),
                const SizedBox(height: AppSpacing.md),
                SearchInput(
                  hintText: isStock
                      ? 'Buscar por nombre, código, categoría...'
                      : 'Buscar movimiento...',
                  controller: _searchCtrl,
                  onChanged: _onSearchChanged,
                ),
              ],
            ),
          ),
          Expanded(
            child: isStock
                ? const StockTabContent(isMobile: true)
                : const MovimientosTabContent(isMobile: true),
          ),
        ],
      ),
      floatingActionButton: isStock
          ? FloatingActionButton(
              onPressed: () => _showInventarioActionsSheet(context),
              backgroundColor: AppColors.primary500,
              foregroundColor: AppColors.brandWhite,
              elevation: 4,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}

Future<void> _showInventarioActionsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grab handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.neutral400,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '¿Qué querés hacer?',
                  style: AppTypography.h3.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            _ActionTile(
              icon: Icons.inventory_2_outlined,
              label: 'Nuevo insumo',
              onTap: () {
                Navigator.of(sheetContext).pop();
                showInsumoFormModal(context);
              },
            ),
            _ActionTile(
              icon: Icons.swap_horiz,
              label: 'Registrar movimiento',
              onTap: () {
                Navigator.of(sheetContext).pop();
                showMovimientoFormModal(context);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      );
    },
  );
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xs,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary500.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: AppColors.primary500, size: 20),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    label,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── DESKTOP ─────────────────────────────────────────────────────────────────

class _DesktopLayout extends ConsumerStatefulWidget {
  @override
  ConsumerState<_DesktopLayout> createState() => _DesktopLayoutState();
}

class _DesktopLayoutState extends ConsumerState<_DesktopLayout> {
  late final TextEditingController _searchCtrl;

  @override
  void initState() {
    super.initState();
    final tab = ref.read(_inventarioTabProvider);
    final initialQuery = tab == 0
        ? ref.read(inventarioFiltrosProvider).query
        : ref.read(movimientoFiltrosProvider).query;
    _searchCtrl = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onTabChange(int newTab) {
    final current = ref.read(_inventarioTabProvider);
    if (current == newTab) return;
    // Limpiar query del tab que dejamos (no queda filtro invisible) y del
    // controller del search global. Se mantienen filtros visibles
    // (categoría/área/tipo).
    _searchCtrl.clear();
    ref.read(inventarioFiltrosProvider.notifier).setQuery('');
    ref.read(movimientoFiltrosProvider.notifier).setQuery('');
    ref.read(_inventarioTabProvider.notifier).set(newTab);
  }

  void _onSearchChanged(String v) {
    final tab = ref.read(_inventarioTabProvider);
    if (tab == 0) {
      ref.read(inventarioFiltrosProvider.notifier).setQuery(v);
    } else {
      ref.read(movimientoFiltrosProvider.notifier).setQuery(v);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(_inventarioTabProvider);
    final isStock = tab == 0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // Header desktop adaptativo según ancho disponible.
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 1200;
              return Container(
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: wide ? AppSpacing.xl2 : AppSpacing.lg,
                  vertical: AppSpacing.xl,
                ),
                child: Row(
                  children: [
                    Text('Inventario', style: AppTypography.h1),
                    SizedBox(width: wide ? AppSpacing.xl : AppSpacing.md),
                    _DesktopTabPill(
                      label: 'Stock',
                      selected: isStock,
                      onTap: () => _onTabChange(0),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _DesktopTabPill(
                      label: 'Movimientos',
                      selected: !isStock,
                      onTap: () => _onTabChange(1),
                    ),
                    // Spacer empuja el search a la derecha. Antes el
                    // SearchInput estaba en un Expanded que lo estiraba
                    // al ancho restante (se veía demasiado largo). Ahora
                    // el search tiene 320 px fijo — mismo patrón que
                    // StickyTopbar usa en las demás páginas.
                    const Spacer(),
                    SizedBox(
                      width: 320,
                      child: SearchInput(
                        hintText: isStock
                            ? (wide
                                ? 'Buscar por nombre, código, proveedor...'
                                : 'Buscar...')
                            : 'Buscar movimiento...',
                        controller: _searchCtrl,
                        onChanged: _onSearchChanged,
                      ),
                    ),
                    if (isStock) ...[
                      const SizedBox(width: AppSpacing.sm),
                      _InventarioPrimaryButton(
                        label: 'Nuevo insumo',
                        onPressed: () => showInsumoFormModal(context),
                        iconOnly: !wide,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _InventarioPrimaryButton(
                        label: 'Registrar movimiento',
                        onPressed: () => showMovimientoFormModal(context),
                        icon: Icons.swap_horiz,
                        iconOnly: !wide,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: isStock
                ? const StockTabContent(isMobile: false)
                : const MovimientosTabContent(isMobile: false),
          ),
        ],
      ),
    );
  }
}

// ─── BUTTONS ─────────────────────────────────────────────────────────────────

class _InventarioPrimaryButton extends StatelessWidget {
  const _InventarioPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon = Icons.add,
    this.iconOnly = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData icon;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: iconOnly ? label : '',
      child: Material(
        color: AppColors.primary500,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: iconOnly ? AppSpacing.sm : AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: AppColors.brandWhite),
                if (!iconOnly) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    label,
                    style: AppTypography.small.copyWith(
                      color: AppColors.brandWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopTabPill extends StatelessWidget {
  const _DesktopTabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary500 : AppColors.neutral100,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Text(
            label,
            style: AppTypography.small.copyWith(
              color: selected ? AppColors.brandWhite : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
