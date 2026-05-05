// lib/presentation/pages/admin/inventario/inventario_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/breakpoints.dart';
import '../../../providers/inventario_provider.dart';
import '../../../widgets/shared/mobile_screen_header.dart';
import '../../../widgets/shared/mobile_tabs_row.dart';
import '../../../widgets/shared/search_input.dart';
import 'widgets/movimiento_form_modal.dart';
import 'widgets/movimientos_placeholder.dart';
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

class _MobileLayout extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(_inventarioTabProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          MobileScreenHeader(
            title: 'Inventario',
            bottom: MobileTabsRow(
              labels: const ['Stock', 'Movimientos'],
              selectedIndex: tab,
              onTap: (i) => ref.read(_inventarioTabProvider.notifier).set(i),
            ),
          ),
          Expanded(
            child: tab == 0
                ? const StockTabContent(isMobile: true)
                : const MovimientosPlaceholder(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showInventarioActionsSheet(context),
        backgroundColor: AppColors.primary500,
        foregroundColor: AppColors.brandWhite,
        elevation: 4,
        child: const Icon(Icons.add),
      ),
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
                _todoNuevoInsumo(context);
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
    _searchCtrl = TextEditingController(
      text: ref.read(inventarioFiltrosProvider).query,
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(_inventarioTabProvider);

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
                      selected: tab == 0,
                      onTap: () =>
                          ref.read(_inventarioTabProvider.notifier).set(0),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _DesktopTabPill(
                      label: 'Movimientos',
                      selected: tab == 1,
                      onTap: () =>
                          ref.read(_inventarioTabProvider.notifier).set(1),
                    ),
                    const Spacer(),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: wide ? 320 : 220),
                        child: SearchInput(
                          hintText: wide
                              ? 'Buscar por nombre, código, proveedor...'
                              : 'Buscar...',
                          controller: _searchCtrl,
                          onChanged: (v) => ref
                              .read(inventarioFiltrosProvider.notifier)
                              .setQuery(v),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _InventarioPrimaryButton(
                      label: 'Nuevo insumo',
                      onPressed: () => _todoNuevoInsumo(context),
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
                ),
              );
            },
          ),
          Expanded(
            child: tab == 0
                ? const StockTabContent(isMobile: false)
                : const MovimientosPlaceholder(),
          ),
        ],
      ),
    );
  }
}

// ─── ACTIONS (TODO) ──────────────────────────────────────────────────────────

void _todoNuevoInsumo(BuildContext context) {
  // TODO: implementar modal "Nuevo Insumo".
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Nuevo insumo — pendiente'),
      duration: Duration(seconds: 2),
    ),
  );
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
