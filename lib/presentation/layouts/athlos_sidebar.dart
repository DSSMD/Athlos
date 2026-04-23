import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/auth_profile_menu.dart';

/// Agrupa un item de navegación con su sección visual.
/// El mapeo label -> sección se hace en main_layout.dart.
class SidebarItem {
  const SidebarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.section,
    this.badge,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final SidebarSection section;
  final int? badge; // ej: contador de notificaciones
}

enum SidebarSection { principal, operaciones, comercial, sistema }

class AthlosSidebar extends StatelessWidget {
  const AthlosSidebar({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onItemSelected,
    this.collapsed = false,
    this.onToggleCollapsed,
  });

  final List<SidebarItem> items;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final bool collapsed;
  final VoidCallback? onToggleCollapsed;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: collapsed ? 72 : 240,
      color: AppColors.sidebarDark,
      child: ClipRect(
        child: Column(
          children: [
            _buildLogoWithToggle(),
            const SizedBox(height: AppSpacing.sm),
            Expanded(child: _buildNavList()),
            _buildUserFooter(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────── LOGO ──
  Widget _buildLogoWithToggle() {
    const logoAsset = 'assets/images/logoAthLogMovilyPagEscritorio.png';

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          // Logo clickeable — expande/colapsa el sidebar
          Expanded(
            child: onToggleCollapsed != null
                ? MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: onToggleCollapsed,
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Image.asset(
                          logoAsset,
                          height: collapsed ? 28 : 40,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Image.asset(
                      logoAsset,
                      height: collapsed ? 28 : 40,
                      fit: BoxFit.contain,
                    ),
                  ),
          ),
          // Botón menu_open (solo cuando está expandido)
          if (onToggleCollapsed != null && !collapsed)
            IconButton(
              onPressed: onToggleCollapsed,
              icon: const Icon(
                Icons.menu_open,
                color: AppColors.neutral400,
                size: 20,
              ),
              tooltip: 'Colapsar',
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────── NAV ITEMS ──
  Widget _buildNavList() {
    // Agrupar items por sección preservando el índice original
    final Map<SidebarSection, List<_IndexedItem>> grouped = {};
    for (var i = 0; i < items.length; i++) {
      grouped
          .putIfAbsent(items[i].section, () => [])
          .add(_IndexedItem(index: i, item: items[i]));
    }

    const sectionOrder = [
      SidebarSection.principal,
      SidebarSection.operaciones,
      SidebarSection.comercial,
      SidebarSection.sistema,
    ];
    const sectionLabels = {
      SidebarSection.principal: null, // sin encabezado
      SidebarSection.operaciones: 'OPERACIONES',
      SidebarSection.comercial: 'COMERCIAL',
      SidebarSection.sistema: 'SISTEMA',
    };

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      children: [
        for (final section in sectionOrder)
          if (grouped[section]?.isNotEmpty ?? false) ...[
            if (sectionLabels[section] != null && !collapsed)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.xs,
                ),
                child: ClipRect(
                  child: Text(
                    sectionLabels[section]!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.neutral500,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.clip,
                    softWrap: false,
                  ),
                ),
              )
            else
              const SizedBox(height: AppSpacing.sm),
            ...grouped[section]!.map(
              (entry) => _SidebarItemTile(
                item: entry.item,
                selected: entry.index == selectedIndex,
                collapsed: collapsed,
                onTap: () => onItemSelected(entry.index),
              ),
            ),
          ],
      ],
    );
  }

  // ───────────────────────────────────────────────────────── FOOTER ──
  Widget _buildUserFooter() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF1F1F1F))),
      ),
      // ¡AQUÍ ESTÁ LA MAGIA! Llamamos al widget inteligente.
      // Le pasamos el estado "collapsed" del sidebar para que se adapte.
      child: AuthProfileMenu(isCollapsed: collapsed, showFullInfo: true),
    );
  }
}

class _IndexedItem {
  const _IndexedItem({required this.index, required this.item});
  final int index;
  final SidebarItem item;
}

// ══════════════════════════════════════════════════════════════════════════
// TILE — ítem individual con estados hover / selected
// ══════════════════════════════════════════════════════════════════════════

class _SidebarItemTile extends StatefulWidget {
  const _SidebarItemTile({
    required this.item,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  final SidebarItem item;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  State<_SidebarItemTile> createState() => _SidebarItemTileState();
}

class _SidebarItemTileState extends State<_SidebarItemTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.selected
        ? AppColors.primary500.withValues(alpha: 0.15)
        : _hovered
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.transparent;

    final fg = widget.selected ? AppColors.brandWhite : AppColors.neutral400;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: ClipRect(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: widget.selected
                      ? const Border(
                          left: BorderSide(
                            color: AppColors.primary500,
                            width: 3,
                          ),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.selected
                          ? widget.item.selectedIcon
                          : widget.item.icon,
                      color: fg,
                      size: 20,
                    ),
                    if (!widget.collapsed) ...[
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          widget.item.label,
                          style: AppTypography.small.copyWith(
                            color: fg,
                            fontWeight: widget.selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.clip,
                          softWrap: false,
                        ),
                      ),
                      if (widget.item.badge != null) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary500,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            '${widget.item.badge}',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.brandWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
