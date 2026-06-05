// ============================================================================
// produccion_dashboard_page.dart
// Ubicación: lib/presentation/pages/produccion/dashboard/produccion_dashboard_page.dart
// Descripción: Dashboard del rol producción. Dos pestañas:
//   - Métricas (placeholder en Bloque 1 — KPIs reales y gráficos en Bloque 2)
//   - Tareas (lista reactiva de trabajos asignados al usuario logueado)
//
// Replica el patrón del admin dashboard (admin/dashboard/dashboard_page.dart):
// ConsumerStatefulWidget, header diferenciado por breakpoint (MobileScreenHeader
// mobile / header custom desktop), AnimatedSwitcher entre tabs, sin Scaffold
// propio (lo provee el shell de MainLayout).
//
// La tab por defecto al entrar es Métricas (índice 0). Como en Bloque 1 esa
// tab es placeholder, el usuario verá el EmptyState al entrar — intencional
// hasta que Bloque 2 la llene con KPIs y gráficos reales.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/breakpoints.dart';
import '../../../widgets/shared/empty_state.dart';
import '../../../widgets/shared/mobile_screen_header.dart';

import 'widgets/produccion_tareas_tab.dart';

class ProduccionDashboardPage extends ConsumerStatefulWidget {
  const ProduccionDashboardPage({super.key});

  @override
  ConsumerState<ProduccionDashboardPage> createState() =>
      _ProduccionDashboardPageState();
}

class _ProduccionDashboardPageState
    extends ConsumerState<ProduccionDashboardPage> {
  // 0 = Métricas (placeholder en Bloque 1), 1 = Tareas
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Column(
      children: [
        if (isMobile)
          MobileScreenHeader(
            title: 'Dashboard',
            bottom: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Panel del trabajador — Athlos',
                  style: AppTypography.small.copyWith(
                    color: AppColors.brandWhite.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _TabSelector(
                  selected: _selectedTab,
                  onChanged: (i) => setState(() => _selectedTab = i),
                ),
              ],
            ),
          )
        else
          _DashboardDesktopHeader(
            selectedTab: _selectedTab,
            onTabChanged: (i) => setState(() => _selectedTab = i),
          ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: switch (_selectedTab) {
              0 => const _ProduccionMetricasPlaceholder(
                key: ValueKey('metricas'),
              ),
              _ => const ProduccionTareasTab(key: ValueKey('tareas')),
            },
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SELECTOR DE TABS — pills reutilizados en header mobile y desktop
// ═════════════════════════════════════════════════════════════════════════════
class _TabSelector extends StatelessWidget {
  const _TabSelector({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _TabPill(
          label: 'Métricas',
          selected: selected == 0,
          onTap: () => onChanged(0),
        ),
        _TabPill(
          label: 'Tareas',
          selected: selected == 1,
          onTap: () => onChanged(1),
        ),
      ],
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary500 : AppColors.neutral100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTypography.body.copyWith(
            color: selected ? AppColors.brandWhite : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HEADER DESKTOP — título h1 + tabs en una sola fila
// ═════════════════════════════════════════════════════════════════════════════
class _DashboardDesktopHeader extends StatelessWidget {
  const _DashboardDesktopHeader({
    required this.selectedTab,
    required this.onTabChanged,
  });

  final int selectedTab;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl2,
        vertical: AppSpacing.xl,
      ),
      child: Row(
        children: [
          Text('Dashboard de Producción', style: AppTypography.h1),
          const SizedBox(width: AppSpacing.xl),
          _TabSelector(selected: selectedTab, onChanged: onTabChanged),
          const Spacer(),
          Text(
            'Panel del trabajador — Athlos',
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PLACEHOLDER DE LA TAB MÉTRICAS — se llena en Bloque 2
// ═════════════════════════════════════════════════════════════════════════════
class _ProduccionMetricasPlaceholder extends StatelessWidget {
  const _ProduccionMetricasPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl2),
      child: const EmptyState(
        icon: Icons.insights_outlined,
        title: 'Métricas en preparación',
        subtitle:
            'KPIs y gráficos de producción se habilitarán en una próxima entrega.',
      ),
    );
  }
}
