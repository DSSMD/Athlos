// ============================================================================
// dashboard_page.dart
// Ubicación: lib/presentation/pages/admin/dashboard/dashboard_page.dart
// Descripción: Dashboard del administrador. Tres pestañas:
//   - General (KPIs reales, gráficos vivos CustomPainter, tabla de órdenes recientes,
//     alertas de stock de insumos, producción real)
//   - Ventas (placeholder)
//   - Producción (placeholder)
//
// Sigue las convenciones de admin/<modulo> establecidas en usuarios_page.dart:
// ConsumerStatefulWidget, header diferenciado por breakpoint (StickyTopbar
// desktop / MobileScreenHeader mobile), AnimatedSwitcher entre tabs, sin
// Scaffold propio (lo provee el shell admin).
//
// Datos: Consumidos de manera reactiva en tiempo real de los proveedores de Supabase.
// Moneda unificada en "Bs." según requerimiento del cliente.
// ============================================================================

// ignore_for_file: deprecated_member_use

//import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/breakpoints.dart';
import '../../../widgets/shared/mobile_screen_header.dart';

import '../../../providers/orden_provider.dart';
import '../../../providers/insumo_provider.dart';
import '../../../providers/usuario_provider.dart';
import '../../../providers/lote_provider.dart';

import '../../../../domain/models/orden_model.dart';
import '../../../../domain/models/inventario_model.dart';
import '../../../../domain/models/usuario_model.dart';
import '../../../../domain/models/lote_model.dart';

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

    // --- CONSUMO REACTIVO DE BASE DE DATOS ---
    final ordenesAsync = ref.watch(ordenesProvider);
    final inventarioAsync = ref.watch(inventarioProvider);
    final usuariosAsync = ref.watch(usuariosProvider);
    final lotesAsync = ref.watch(lotesListProvider);

    final isLoading = ordenesAsync.isLoading && (ordenesAsync.value?.isEmpty ?? true);

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl2),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final ordenes = ordenesAsync.value ?? [];
    final inventario = inventarioAsync.value ?? [];
    final usuarios = usuariosAsync.value ?? [];
    final lotes = lotesAsync.value ?? [];

    // --- Cálculos de KPIs en tiempo real ---
    final int ordenesActivas = ordenes.where((o) => o.idEstado != 4).length;
    final double ingresosTotales = ordenes.fold<double>(0.0, (sum, o) => sum + o.costoTotal);
    final int stockBajo = inventario.where((item) => item.stockActual < item.stockMinimo).length;
    final int trabajadoresActivos = usuarios.where((u) => u.isTrabajador && u.status == UserStatus.activo).length;

    return Column(
      children: [
        if (isMobile)
          MobileScreenHeader(
            title: 'Dashboard',
            bottom: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resumen del mes — ${DateFormat('MMMM yyyy', 'es').format(DateTime.now())}',
                  style: AppTypography.small.copyWith(
                    color: AppColors.brandWhite.withOpacity(0.7),
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
                0 => _buildGeneralTab(
                    isMobile,
                    ordenes: ordenes,
                    inventario: inventario,
                    lotes: lotes,
                    ordenesActivas: ordenesActivas,
                    ingresosMes: ingresosTotales,
                    stockBajo: stockBajo,
                    trabajadoresActivos: trabajadoresActivos,
                    key: const ValueKey('general'),
                  ),
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
  Widget _buildGeneralTab(
    bool isMobile, {
    required List<OrdenModel> ordenes,
    required List<InventarioItemModel> inventario,
    required List<LoteModel> lotes,
    required int ordenesActivas,
    required double ingresosMes,
    required int stockBajo,
    required int trabajadoresActivos,
    Key? key,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _KpiRow(
          isMobile: isMobile,
          ordenesActivas: ordenesActivas,
          ingresosMes: ingresosMes,
          stockBajo: stockBajo,
          trabajadoresActivos: trabajadoresActivos,
        ),
        const SizedBox(height: AppSpacing.lg),
        _ChartsRow(isMobile: isMobile, ordenes: ordenes),
        const SizedBox(height: AppSpacing.lg),
        _BottomSplit(
          isMobile: isMobile,
          ordenes: ordenes,
          inventario: inventario,
          lotes: lotes,
        ),
      ],
    );
  }

  // ─── TAB: VENTAS (placeholder) ───
  Widget _buildVentasTab({Key? key}) {
    return _PlaceholderTab(
      key: key,
      icon: Icons.bar_chart_outlined,
      title: 'Dashboard de Ventas',
      message: 'Diseño comercial en preparación.',
    );
  }

  // ─── TAB: PRODUCCIÓN (placeholder) ───
  Widget _buildProduccionTab({Key? key}) {
    return _PlaceholderTab(
      key: key,
      icon: Icons.factory_outlined,
      title: 'Dashboard de Producción',
      message: 'Planificador de capacidades en preparación.',
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
        /*
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
        */
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
            'Resumen de Control — Athlos',
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
  const _KpiRow({
    required this.isMobile,
    required this.ordenesActivas,
    required this.ingresosMes,
    required this.stockBajo,
    required this.trabajadoresActivos,
  });

  final bool isMobile;
  final int ordenesActivas;
  final double ingresosMes;
  final int stockBajo;
  final int trabajadoresActivos;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: 'Bs. ', decimalDigits: 0, locale: 'es_BO');

    final kpis = [
      _KpiData(
        label: 'ÓRDENES ACTIVAS',
        value: '$ordenesActivas',
        delta: 'Actualmente en taller',
        deltaColor: AppColors.primary500,
      ),
      _KpiData(
        label: 'INGRESOS TOTALES',
        value: formatter.format(ingresosMes),
        delta: 'Total registrado',
        deltaColor: AppColors.success,
      ),
      _KpiData(
        label: 'STOCK BAJO',
        value: '$stockBajo',
        delta: stockBajo > 0 ? 'Requieren reabastecimiento' : 'Stock en nivel óptimo',
        deltaColor: stockBajo > 0 ? AppColors.error : AppColors.success,
      ),
      _KpiData(
        label: 'TRABAJADORES ACTIVOS',
        value: '$trabajadoresActivos',
        delta: 'Personal en planta',
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              data.value,
              style: AppTypography.h2.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            data.delta,
            style: AppTypography.caption.copyWith(color: data.deltaColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// GRÁFICOS REALES — CustomPainter y Widgets de control
// ═════════════════════════════════════════════════════════════════════════════
class _ChartsRow extends StatelessWidget {
  const _ChartsRow({required this.isMobile, required this.ordenes});
  final bool isMobile;
  final List<OrdenModel> ordenes;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: [
          _BarChartWidget(ordenes: ordenes),
          const SizedBox(height: AppSpacing.lg),
          _DonutChartWidget(ordenes: ordenes),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _BarChartWidget(ordenes: ordenes),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          flex: 1,
          child: _DonutChartWidget(ordenes: ordenes),
        ),
      ],
    );
  }
}

// Gráfico de barras de ingresos semanales real
class _BarChartWidget extends StatelessWidget {
  final List<OrdenModel> ordenes;

  const _BarChartWidget({required this.ordenes});

  @override
  Widget build(BuildContext context) {
    final ahora = DateTime.now();
    final double w1 = _obtenerIngresosSemana(ahora.subtract(const Duration(days: 7)), ahora);
    final double w2 = _obtenerIngresosSemana(ahora.subtract(const Duration(days: 14)), ahora.subtract(const Duration(days: 7)));
    final double w3 = _obtenerIngresosSemana(ahora.subtract(const Duration(days: 21)), ahora.subtract(const Duration(days: 14)));
    final double w4 = _obtenerIngresosSemana(ahora.subtract(const Duration(days: 28)), ahora.subtract(const Duration(days: 21)));

    final ingresos = [w4, w3, w2, w1];
    final maxIngreso = ingresos.reduce((a, b) => a > b ? a : b);
    const double maxBarHeight = 140.0;

    return Container(
      height: 250,
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
            'INGRESOS SEMANALES (ÚLTIMAS 4 SEMANAS)',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(4, (index) {
              final val = ingresos[index];
              final heightRatio = maxIngreso > 0 ? (val / maxIngreso) : 0.0;
              final barHeight = (heightRatio * maxBarHeight).clamp(12.0, maxBarHeight);

              return Column(
                children: [
                  Text(
                    'Bs. ${val.toStringAsFixed(0)}',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 36,
                    height: barHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary500,
                          AppColors.primary500.withOpacity(0.7),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary500.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Semana ${index + 1}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  double _obtenerIngresosSemana(DateTime inicio, DateTime fin) {
    return ordenes
        .where((o) => o.fechaOrden.isAfter(inicio) && o.fechaOrden.isBefore(fin))
        .fold<double>(0.0, (sum, o) => sum + o.costoTotal);
  }
}

// Gráfico circular Donut para estado de órdenes real
class _DonutChartWidget extends StatelessWidget {
  final List<OrdenModel> ordenes;

  const _DonutChartWidget({required this.ordenes});

  @override
  Widget build(BuildContext context) {
    final int pendientes = ordenes.where((o) => o.idEstado == 1).length;
    final int produccion = ordenes.where((o) => o.idEstado == 2).length;
    final int finalizadas = ordenes.where((o) => o.idEstado == 3).length;
    final int entregadas = ordenes.where((o) => o.idEstado == 4).length;
    final int total = pendientes + produccion + finalizadas + entregadas;

    return Container(
      height: 250,
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
            'ÓRDENES POR ESTADO',
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Center(
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(110, 110),
                          painter: _DonutChartPainter(
                            pendientes: pendientes,
                            produccion: produccion,
                            finalizadas: finalizadas,
                            entregadas: entregadas,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$total',
                              style: AppTypography.h3.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Órdenes',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LegendItem(label: 'Pendiente', count: pendientes, total: total, color: Colors.orange),
                  const SizedBox(height: 6),
                  _LegendItem(label: 'Producción', count: produccion, total: total, color: AppColors.primary500),
                  const SizedBox(height: 6),
                  _LegendItem(label: 'Finalizada', count: finalizadas, total: total, color: Colors.green),
                  const SizedBox(height: 6),
                  _LegendItem(label: 'Entregada', count: entregadas, total: total, color: Colors.blue),
                ],
              ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _LegendItem({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double pct = total > 0 ? (count / total) * 100 : 0.0;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$label: $count',
              style: AppTypography.caption.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 10,
              ),
            ),
            Text(
              '${pct.toStringAsFixed(0)}%',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
                fontSize: 8.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DonutChartPainter extends CustomPainter {
  final int pendientes;
  final int produccion;
  final int finalizadas;
  final int entregadas;

  _DonutChartPainter({
    required this.pendientes,
    required this.produccion,
    required this.finalizadas,
    required this.entregadas,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final int total = pendientes + produccion + finalizadas + entregadas;
    if (total == 0) {
      final paint = Paint()
        ..color = Colors.grey.shade200
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12.0;
      canvas.drawCircle(size.center(Offset.zero), size.width / 2 - 6, paint);
      return;
    }

    final double sweep1 = (pendientes / total) * 2 * 3.14159265;
    final double sweep2 = (produccion / total) * 2 * 3.14159265;
    final double sweep3 = (finalizadas / total) * 2 * 3.14159265;
    final double sweep4 = (entregadas / total) * 2 * 3.14159265;

    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2 - 6);

    double startAngle = -3.14159265 / 2; // Empieza arriba (-90 grados)

    final paint1 = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round;

    final paint2 = Paint()
      ..color = AppColors.primary500
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round;

    final paint3 = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round;

    final paint4 = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12.0
      ..strokeCap = StrokeCap.round;

    if (sweep1 > 0) {
      canvas.drawArc(rect, startAngle, sweep1, false, paint1);
      startAngle += sweep1;
    }
    if (sweep2 > 0) {
      canvas.drawArc(rect, startAngle, sweep2, false, paint2);
      startAngle += sweep2;
    }
    if (sweep3 > 0) {
      canvas.drawArc(rect, startAngle, sweep3, false, paint3);
      startAngle += sweep3;
    }
    if (sweep4 > 0) {
      canvas.drawArc(rect, startAngle, sweep4, false, paint4);
      startAngle += sweep4;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ═════════════════════════════════════════════════════════════════════════════
// SECCIÓN DE ABAJO — Tabla órdenes reales + Alertas stock reales + Producción real
// ═════════════════════════════════════════════════════════════════════════════
class _BottomSplit extends StatelessWidget {
  const _BottomSplit({
    required this.isMobile,
    required this.ordenes,
    required this.inventario,
    required this.lotes,
  });

  final bool isMobile;
  final List<OrdenModel> ordenes;
  final List<InventarioItemModel> inventario;
  final List<LoteModel> lotes;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: [
          _OrdenesRecientes(ordenes: ordenes),
          const SizedBox(height: AppSpacing.lg),
          _AlertasStock(items: inventario),
          const SizedBox(height: AppSpacing.lg),
          _ProduccionHoy(lotes: lotes),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: _OrdenesRecientes(ordenes: ordenes)),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _AlertasStock(items: inventario),
              const SizedBox(height: AppSpacing.lg),
              _ProduccionHoy(lotes: lotes),
            ],
          ),
        ),
      ],
    );
  }
}

class _OrdenesRecientes extends StatelessWidget {
  final List<OrdenModel> ordenes;

  const _OrdenesRecientes({required this.ordenes});

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
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (ordenes.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: Text('No hay órdenes registradas.')),
            )
          else
            _OrdenesTabla(ordenes: ordenes.take(5).toList()),
        ],
      ),
    );
  }
}

class _OrdenesTabla extends StatelessWidget {
  final List<OrdenModel> ordenes;

  const _OrdenesTabla({required this.ordenes});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: 'Bs. ', decimalDigits: 2, locale: 'es_BO');

    if (context.isMobile) {
      return Column(
        children: [
          for (final o in ordenes) ...[
            _OrdenCardMobile(
              orden: '#${o.numOrden.length > 8 ? o.numOrden.substring(0, 8).toUpperCase() : o.numOrden.toUpperCase()}',
              cliente: o.clienteNombre,
              producto: o.producto,
              total: formatter.format(o.costoTotal),
              estado: o.estadoOrden,
              idEstado: o.idEstado,
            ),
            if (o != ordenes.last)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              _col('ORDEN', 2),
              _col('CLIENTE', 2),
              _col('PRODUCTO', 2),
              _col('TOTAL', 2),
              _col('ESTADO', 2),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        for (final o in ordenes) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    '#${o.numOrden.length > 8 ? o.numOrden.substring(0, 8).toUpperCase() : o.numOrden.toUpperCase()}',
                    style: AppTypography.small.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(o.clienteNombre, style: AppTypography.small),
                ),
                Expanded(
                  flex: 2,
                  child: Text(o.producto, style: AppTypography.small, overflow: TextOverflow.ellipsis, maxLines: 1),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    formatter.format(o.costoTotal),
                    style: AppTypography.small.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _EstadoChip(
                    estadoLabel: o.estadoOrden,
                    idEstado: o.idEstado,
                  ),
                ),
              ],
            ),
          ),
          if (o != ordenes.last)
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

class _OrdenCardMobile extends StatelessWidget {
  const _OrdenCardMobile({
    required this.orden,
    required this.cliente,
    required this.producto,
    required this.total,
    required this.estado,
    required this.idEstado,
  });

  final String orden;
  final String cliente;
  final String producto;
  final String total;
  final String estado;
  final int idEstado;

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
              _EstadoChip(estadoLabel: estado, idEstado: idEstado),
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

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.estadoLabel, required this.idEstado});
  final String estadoLabel;
  final int idEstado;

  @override
  Widget build(BuildContext context) {
    final color = switch (idEstado) {
      1 => Colors.orange,       // Pendiente
      2 => AppColors.primary500, // En producción
      3 => Colors.green,        // Finalizada
      4 => Colors.blue,         // Entregada
      _ => Colors.grey,
    };
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          estadoLabel,
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
  final List<InventarioItemModel> items;

  const _AlertasStock({required this.items});

  @override
  Widget build(BuildContext context) {
    // Obtenemos los insumos con stock menor al mínimo
    final alertas = items
        .where((item) => item.stockActual < item.stockMinimo)
        .take(5)
        .toList();

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
          if (alertas.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(
                child: Text(
                  'Todo el stock está óptimo',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          if (alertas.isNotEmpty) ...[
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
                      child: Text(a.nombre, style: AppTypography.small),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(
                        a.stockActual.toStringAsFixed(0),
                        style: AppTypography.small.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Text(a.stockMinimo.toStringAsFixed(0), style: AppTypography.small),
                    ),
                  ],
                ),
              ),
              if (a != alertas.last)
                const Divider(height: 1, color: AppColors.border),
            ],
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
  final List<LoteModel> lotes;

  const _ProduccionHoy({required this.lotes});

  @override
  Widget build(BuildContext context) {
    final int lotesActivos = lotes.where((l) => l.estado != 'Terminado').length;
    final int piezasProduccion = lotes.where((l) => l.estado != 'Terminado').fold<int>(0, (sum, l) => sum + l.cantidad);
    final double eficienciaVal = lotes.isEmpty ? 100.0 : (lotes.where((l) => l.estado == 'Terminado').length / lotes.length) * 100;

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
          Text('Producción hoy', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.lg),
          _StatRow(label: 'Piezas en proceso', value: '$piezasProduccion'),
          const SizedBox(height: AppSpacing.sm),
          _StatRow(
            label: 'Eficiencia',
            value: '${eficienciaVal.toStringAsFixed(0)}%',
            valueColor: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.sm),
          _StatRow(label: 'Lotes activos', value: '$lotesActivos'),
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
