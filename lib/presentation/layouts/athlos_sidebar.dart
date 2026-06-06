import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../widgets/auth_profile_menu.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/providers/auth_provider.dart';
import '../providers/notificacion_provider.dart';
import '../widgets/notificaciones/notification_panel_launcher.dart';

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

// sidebar_menu_config.dart

class SidebarMenuConfig {
  // ─── PRINCIPAL ──────────────────────────────────────────────────
  static const itemDashboard = SidebarItem(
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    label: 'Dashboard',
    section: SidebarSection.principal,
  );

  static const itemEspera = SidebarItem(
    icon: Icons.hourglass_empty_outlined,
    selectedIcon: Icons.hourglass_empty,
    label: 'En Espera',
    section: SidebarSection.principal,
  );

  // ─── OPERACIONES ────────────────────────────────────────────────
  static const itemInventario = SidebarItem(
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
    label: 'Inventario',
    section: SidebarSection.operaciones,
  );

  static const itemProduccion = SidebarItem(
    icon: Icons.precision_manufacturing_outlined,
    selectedIcon: Icons.precision_manufacturing,
    label: 'Producción',
    section: SidebarSection.operaciones,
  );

  static const itemPlantillas = SidebarItem(
    icon: Icons.checkroom_outlined,
    selectedIcon: Icons.checkroom,
    label: 'Plantillas',
    section: SidebarSection.operaciones,
  );

  static const itemConjuntos = SidebarItem(
    icon: Icons.view_comfy_outlined,
    selectedIcon: Icons.view_comfy,
    label: 'Conjuntos',
    section: SidebarSection.operaciones,
  );

  // ─── COMERCIAL ──────────────────────────────────────────────────
  static const itemOrdenes = SidebarItem(
    icon: Icons.assignment_outlined,
    selectedIcon: Icons.assignment,
    label: 'Órdenes',
    section: SidebarSection.comercial,
  );

  static const itemClientes = SidebarItem(
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
    label: 'Clientes',
    section: SidebarSection.comercial,
  );

  static const itemPagos = SidebarItem(
    // 👈 Aquí está definido itemPagos
    icon: Icons.payments_outlined,
    selectedIcon: Icons.payments,
    label: 'Pagos',
    section: SidebarSection.comercial,
  );

  static const itemBalance = SidebarItem(
    // 👈 Aquí está definido itemBalance
    icon: Icons.account_balance_wallet_outlined,
    selectedIcon: Icons.account_balance_wallet,
    label: 'Balance',
    section: SidebarSection.comercial,
  );

  // ─── SISTEMA ────────────────────────────────────────────────────
  static const itemUsuarios = SidebarItem(
    icon: Icons.manage_accounts_outlined,
    selectedIcon: Icons.manage_accounts,
    label: 'Usuarios',
    section: SidebarSection.sistema,
  );

  static const itemConfiguracion = SidebarItem(
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    label: 'Configuración',
    section: SidebarSection.sistema,
  );

  static const itemNotificaciones = SidebarItem(
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications,
    label: 'Avisos',
    section: SidebarSection.sistema,
    badge: 4,
  );

  static Map<String, List<SidebarItem>> get itemsPorRol => {
    '1': [
      itemDashboard, // 0
      itemOrdenes, // 1
      itemInventario, // 2
      itemProduccion, // 3
      itemPlantillas, // 4
      itemConjuntos, // 5 💡 NUEVO ÍTEM INDEPENDIENTE
      itemClientes, // 6
      // itemPagos,          // 7 (Placeholder comentado por ahora)
      // itemBalance,        // 8 (Placeholder comentado por ahora)
      itemUsuarios, // 7 (Ahora índice 7 en visual, antes 9)
      // itemConfiguracion,  // 10 (Placeholder comentado por ahora)
      itemNotificaciones, // 8 Avisos — abre el panel, no navega a page
    ],
    '2': [
      // PRODUCCIÓN: 3 ítems base + Avisos
      itemDashboard,
      itemInventario,
      itemProduccion,
      itemNotificaciones, // Avisos — abre el panel, no navega a page
    ],
    '3': [
      // VENTAS: ítems base + Avisos
      itemDashboard,
      itemOrdenes,
      itemClientes,
      // itemPagos,          // (Placeholder comentado por ahora)
      itemNotificaciones, // Avisos — abre el panel, no navega a page
    ],
    '4': [
      // INVITADO: 2 ítems
      itemDashboard,
      itemEspera,
    ],
  };
}

class AthlosSidebar extends ConsumerWidget {
  const AthlosSidebar({
    super.key,
    required this.items, // Lo mantenemos en el constructor para no romper el MainLayout que ya lo llama
    required this.selectedIndex,
    required this.onItemSelected,
    this.collapsed = false,
    this.onToggleCollapsed,
  });

  final List<SidebarItem>
  items; // Aunque lo recibimos, lo ignoraremos internamente
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final bool collapsed;
  final VoidCallback? onToggleCollapsed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 5. MAGIA AQUÍ: Leemos el rol del usuario directamente en el Sidebar
    final profileAsync = ref.watch(userProfileProvider);
    final roleId =
        profileAsync.value?['id_rol']?.toString() ??
        '4'; // Por defecto '4' (invitado) si algo falla

    // 6. Obtenemos la lista dinámica según el rol
    final dynamicItems = SidebarMenuConfig.itemsPorRol[roleId] ?? [];

    // 7. Contador de no-leídas para inyectar al badge dinámico del item Avisos.
    final unreadCount = ref.watch(unreadNotificacionesCountProvider);

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
            // 8. Pasamos items + count para que el tile de Avisos use el badge dinámico.
            Expanded(child: _buildNavList(context, dynamicItems, unreadCount)),
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
  Widget _buildNavList(
    BuildContext context,
    List<SidebarItem> dynamicItems,
    int unreadCount,
  ) {
    final Map<SidebarSection, List<_IndexedItem>> grouped = {};

    // Iteramos sobre dynamicItems en lugar de "this.items"
    for (var i = 0; i < dynamicItems.length; i++) {
      grouped
          .putIfAbsent(dynamicItems[i].section, () => [])
          .add(_IndexedItem(index: i, item: dynamicItems[i]));
    }

    const sectionOrder = [
      SidebarSection.principal,
      SidebarSection.operaciones,
      SidebarSection.comercial,
      SidebarSection.sistema,
    ];

    const sectionLabels = {
      SidebarSection.principal: null,
      SidebarSection.operaciones: 'Operaciones',
      SidebarSection.comercial: 'Comercial',
      SidebarSection.sistema: 'Sistema',
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
            ...grouped[section]!.map((entry) {
              // Avisos no navega a una page: en lugar de cambiar el índice,
              // dispara el panel de notificaciones. El badge se resuelve
              // dinámicamente con el contador real (no con item.badge
              // hardcodeado en la constante).
              final esAvisos = identical(
                entry.item,
                SidebarMenuConfig.itemNotificaciones,
              );
              return _SidebarItemTile(
                item: entry.item,
                selected: !esAvisos && entry.index == selectedIndex,
                collapsed: collapsed,
                onTap: esAvisos
                    ? () => showNotificationsPanel(context)
                    : () => onItemSelected(entry.index),
                badgeOverride: esAvisos
                    ? (unreadCount > 0 ? unreadCount : null)
                    : null,
              );
            }),
          ],
      ],
    );
  }

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
// ───────────────────────────────────────────────────────── FOOTER ──

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
    this.badgeOverride,
  });

  final SidebarItem item;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  /// Si está seteado, anula `item.badge` al renderizar. Útil para items con
  /// conteo dinámico (Avisos lee unreadNotificacionesCountProvider).
  final int? badgeOverride;

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
                      if ((widget.badgeOverride ?? widget.item.badge) !=
                          null) ...[
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
                            '${widget.badgeOverride ?? widget.item.badge}',
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
