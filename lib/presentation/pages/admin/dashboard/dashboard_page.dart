// ============================================================================
// dashboard_page.dart
// Ubicación: lib/presentation/pages/admin/dashboard/dashboard_page.dart
// Descripción: Dashboard del administrador. Tres pestañas:
//   - General (poblada con KPIs, gráficos placeholder, tabla órdenes recientes,
//     alertas de stock, producción hoy)
//   - Ventas (placeholder)
//   - Producción (placeholder)
//
// Sigue las convenciones de admin/<modulo> establecidas en usuarios_page.dart:
// ConsumerStatefulWidget, header diferenciado por breakpoint (StickyTopbar
// desktop / MobileScreenHeader mobile), AnimatedSwitcher entre tabs, sin
// Scaffold propio (lo provee el shell admin).
//
// Datos: hoy todos hardcodeados. Cuando el backend exponga el endpoint de
// Moore-Hodgson y los demás resúmenes, los KPIs y la tabla pasan a consumir
// providers reales con `ref.watch(...).when(loading, error, data)`.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/breakpoints.dart';

import '../../../widgets/shared/mobile_screen_header.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  int _selectedTab = 0; // 0=General, 1=Ventas, 2=Producción

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
                  'Resumen del mes — Marzo 2026',
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
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl2),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: switch (_selectedTab) {
                0 => _buildGeneralTab(isMobile, key: const ValueKey('general')),
                1 => _buildVentasTab(key: const ValueKey('ventas')),
                _ => _buildProduccionTab(key: const ValueKey('produccion')),
              },
            ),
          ),
        ),
      ],
    );
  }

  // ─── TAB: GENERAL ───
  Widget _buildGeneralTab(bool isMobile, {Key? key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _KpiRow(isMobile: isMobile),
        const SizedBox(height: AppSpacing.lg),
        _ChartsRow(isMobile: isMobile),
        const SizedBox(height: AppSpacing.lg),
        _BottomSplit(isMobile: isMobile),
      ],
    );
  }

  // ─── TAB: VENTAS (placeholder) ───
  Widget _buildVentasTab({Key? key}) {
    return _PlaceholderTab(
      key: key,
      icon: Icons.bar_chart_outlined,
      title: 'Dashboard de Ventas',
      message: 'Pendiente de diseño en Figma.',
    );
  }

  // ─── TAB: PRODUCCIÓN (placeholder) ───
  Widget _buildProduccionTab({Key? key}) {
    return _PlaceholderTab(
      key: key,
      icon: Icons.factory_outlined,
      title: 'Dashboard de Producción',
      message: 'Pendiente de diseño en Figma.',
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SELECTOR DE TABS
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
          label: 'General',
          selected: selected == 0,
          onTap: () => onChanged(0),
        ),
        _TabPill(
          label: 'Ventas',
          selected: selected == 1,
          onTap: () => onChanged(1),
        ),
        _TabPill(
          label: 'Producción',
          selected: selected == 2,
          onTap: () => onChanged(2),
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
// HEADER DE DESKTOP — título + tabs en una sola fila (sin search ni botón)
// El dashboard es pantalla de stats, no necesita el search del StickyTopbar
// estándar. Replicamos el styling (border-bottom, padding) sin la lógica
// de search/new que no aplica acá.
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
          Text('Dashboard', style: AppTypography.h1),
          const SizedBox(width: AppSpacing.xl),
          _TabSelector(selected: selectedTab, onChanged: onTabChanged),
          const Spacer(),
          Text(
            'Resumen del mes — Marzo 2026',
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// KPIs ROW — 4 cards: grid 2x2 mobile / 4 columnas desktop
// ═════════════════════════════════════════════════════════════════════════════
class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.isMobile});
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final kpis = [
      const _KpiData(
        label: 'ÓRDENES ACTIVAS',
        value: '147',
        delta: '+12.5% vs Feb',
        deltaColor: AppColors.success,
      ),
      const _KpiData(
        label: 'INGRESOS DEL MES',
        value: '\$84,320',
        delta: '+8.2%',
        deltaColor: AppColors.success,
      ),
      const _KpiData(
        label: 'STOCK BAJO',
        value: '23',
        delta: 'Requieren atención',
        deltaColor: AppColors.error,
      ),
      const _KpiData(
        label: 'TRABAJADORES ACTIVOS',
        value: '18',
        delta: 'Todos asignados',
        deltaColor: AppColors.success,
      ),
    ];

    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.1,
        children: kpis.map((k) => _KpiCardWidget(data: k)).toList(),
      );
    }

    return Row(
      children: [
        for (var i = 0; i < kpis.length; i++) ...[
          Expanded(child: _KpiCardWidget(data: kpis[i])),
          if (i < kpis.length - 1) const SizedBox(width: AppSpacing.lg),
        ],
      ],
    );
  }
}

class _KpiData {
  final String label;
  final String value;
  final String delta;
  final Color deltaColor;

  const _KpiData({
    required this.label,
    required this.value,
    required this.delta,
    required this.deltaColor,
  });
}

class _KpiCardWidget extends StatelessWidget {
  const _KpiCardWidget({required this.data});
  final _KpiData data;

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
          Text(
            data.label,
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            data.value,
            style: AppTypography.h1.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            data.delta,
            style: AppTypography.caption.copyWith(color: data.deltaColor),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CHARTS — placeholders por ahora; se conectan a charts reales después
// ═════════════════════════════════════════════════════════════════════════════
class _ChartsRow extends StatelessWidget {
  const _ChartsRow({required this.isMobile});
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: const [
          _ChartPlaceholder(
            title: '[Gráfico de barras — ingresos semanales del mes]',
            height: 240,
          ),
          SizedBox(height: AppSpacing.lg),
          _ChartPlaceholder(
            title: '[Gráfico circular — órdenes por estado]',
            height: 240,
          ),
        ],
      );
    }
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _ChartPlaceholder(
            title: '[Gráfico de barras — ingresos semanales del mes]',
            height: 320,
          ),
        ),
        SizedBox(width: AppSpacing.lg),
        Expanded(
          flex: 1,
          child: _ChartPlaceholder(
            title:
                '[Gráfico circular — órdenes por estado: completadas, en producción, pendientes]',
            height: 320,
          ),
        ),
      ],
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder({required this.title, required this.height});
  final String title;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      alignment: Alignment.center,
      child: Text(
        title,
        style: AppTypography.small.copyWith(color: AppColors.textMuted),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SECCIÓN DE ABAJO — Tabla órdenes + Alertas stock + Producción hoy
// ═════════════════════════════════════════════════════════════════════════════
class _BottomSplit extends StatelessWidget {
  const _BottomSplit({required this.isMobile});
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: const [
          _OrdenesRecientes(),
          SizedBox(height: AppSpacing.lg),
          _AlertasStock(),
          SizedBox(height: AppSpacing.lg),
          _ProduccionHoy(),
        ],
      );
    }
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _OrdenesRecientes()),
        SizedBox(width: AppSpacing.lg),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _AlertasStock(),
              SizedBox(height: AppSpacing.lg),
              _ProduccionHoy(),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrdenesRecientes extends StatelessWidget {
  const _OrdenesRecientes();

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Órdenes recientes', style: AppTypography.h3),
              const Spacer(),
              OutlinedButton(
                onPressed: () {
                  // TODO: navegar a lista de órdenes
                },
                child: const Text('Ver todo'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Tabla mock con 4 filas del Figma
          const _OrdenesTablaMock(),
        ],
      ),
    );
  }
}

class _OrdenesTablaMock extends StatelessWidget {
  const _OrdenesTablaMock();

  // Filas mock compartidas entre layouts
  static final _filas = <(String, String, String, String, _EstadoBadge)>[
    (
      '#ORD-2847',
      'María López',
      'Camisas polo',
      r'$1,250',
      _EstadoBadge.completada,
    ),
    (
      '#ORD-2846',
      'Carlos Ruiz',
      'Pantalones cargo',
      r'$3,480',
      _EstadoBadge.enProduccion,
    ),
    (
      '#ORD-2845',
      'Ana Torres',
      'Uniformes esc.',
      r'$890',
      _EstadoBadge.pendiente,
    ),
    (
      '#ORD-2844',
      'Pedro Sánchez',
      'Chalecos ind.',
      r'$2,100',
      _EstadoBadge.urgente,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (context.isMobile) {
      return Column(
        children: [
          for (final fila in _filas) ...[
            _OrdenCardMobile(
              orden: fila.$1,
              cliente: fila.$2,
              producto: fila.$3,
              total: fila.$4,
              estado: fila.$5,
            ),
            if (fila != _filas.last)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      );
    }

    // Desktop: tabla horizontal (mantiene el layout anterior)
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              _col('ORDEN', 2),
              _col('CLIENTE', 2),
              _col('PRODUCTO', 2),
              _col('TOTAL', 1),
              _col('ESTADO', 2),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        for (final fila in _filas) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(fila.$1, style: AppTypography.small),
                ),
                Expanded(
                  flex: 2,
                  child: Text(fila.$2, style: AppTypography.small),
                ),
                Expanded(
                  flex: 2,
                  child: Text(fila.$3, style: AppTypography.small),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    fila.$4,
                    style: AppTypography.small.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(flex: 2, child: _EstadoChip(estado: fila.$5)),
              ],
            ),
          ),
          if (fila != _filas.last)
            const Divider(height: 1, color: AppColors.border),
        ],
      ],
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

// Card de una orden en mobile — toda la info de la fila apilada vertical
class _OrdenCardMobile extends StatelessWidget {
  const _OrdenCardMobile({
    required this.orden,
    required this.cliente,
    required this.producto,
    required this.total,
    required this.estado,
  });

  final String orden;
  final String cliente;
  final String producto;
  final String total;
  final _EstadoBadge estado;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  orden,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _EstadoChip(estado: estado),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('$cliente · $producto', style: AppTypography.small),
          const SizedBox(height: AppSpacing.xs),
          Text(
            total,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

enum _EstadoBadge { completada, enProduccion, pendiente, urgente }

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.estado});
  final _EstadoBadge estado;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (estado) {
      _EstadoBadge.completada => ('Completada', AppColors.success),
      _EstadoBadge.enProduccion => ('En producción', Colors.amber),
      _EstadoBadge.pendiente => ('Pendiente', Colors.blue),
      _EstadoBadge.urgente => ('Urgente', AppColors.error),
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AlertasStock extends StatelessWidget {
  const _AlertasStock();

  @override
  Widget build(BuildContext context) {
    final alertas = [
      ('Hilo negro #120', '12', '50'),
      ('Tela poliéster azul', '45', '100'),
      ('Elástico 3cm', '25', '50'),
    ];
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Alertas de stock', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.lg),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [_col('INSUMO', 3), _col('STOCK', 1), _col('MÍN.', 1)],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          for (final a in alertas) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(a.$1, style: AppTypography.small),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      a.$2,
                      style: AppTypography.small.copyWith(
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(a.$3, style: AppTypography.small),
                  ),
                ],
              ),
            ),
            if (a != alertas.last)
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

class _ProduccionHoy extends StatelessWidget {
  const _ProduccionHoy();

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Text('Producción hoy', style: AppTypography.h3),
          SizedBox(height: AppSpacing.lg),
          _StatRow(label: 'Piezas hoy', value: '342'),
          SizedBox(height: AppSpacing.sm),
          _StatRow(
            label: 'Eficiencia',
            value: '87%',
            valueColor: AppColors.success,
          ),
          SizedBox(height: AppSpacing.sm),
          _StatRow(label: 'Lotes activos', value: '8'),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTypography.small)),
        Text(
          value,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PLACEHOLDER PARA TABS VENTAS / PRODUCCIÓN
// ═════════════════════════════════════════════════════════════════════════════
class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl2),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: AppTypography.h3.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            style: AppTypography.small.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
