// lib/presentation/pages/admin/balance/balance_page.dart

// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:workspace/data/services/balance_service.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/breakpoints.dart';
import '../../../widgets/shared/mobile_screen_header.dart';

import '../../../providers/balance_provider.dart';
import '../../../../domain/models/balance_model.dart';

class BalancePage extends ConsumerStatefulWidget {
  const BalancePage({super.key});

  @override
  ConsumerState<BalancePage> createState() => _BalancePageState();
}

class _BalancePageState extends ConsumerState<BalancePage> {
  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final periodo = ref.watch(balancePeriodoProvider);

    return Column(
      children: [
        // ── Header responsive ───────────────────────────────────────────────
        if (isMobile)
          MobileScreenHeader(
            title: 'Balance',
            bottom: _PeriodoChips(
              selected: periodo,
              onChanged: (p) =>
                  ref.read(balancePeriodoProvider.notifier).state = p,
            ),
          )
        else
          _BalanceDesktopHeader(
            periodo: periodo,
            onPeriodoChanged: (p) =>
                ref.read(balancePeriodoProvider.notifier).state = p,
          ),

        // ── Contenido ───────────────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // KPI Cards
                _KpiSection(periodo: periodo, isMobile: isMobile),
                const SizedBox(height: AppSpacing.xl),

                // Gráfico de barras dobles
                _GraficoBalanceCard(periodo: periodo, isMobile: isMobile),
                const SizedBox(height: AppSpacing.xl),

                // Tabla de órdenes con detalle financiero
                _TablaOrdenesCard(periodo: periodo, isMobile: isMobile),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HEADER DESKTOP
// ══════════════════════════════════════════════════════════════════════════════
class _BalanceDesktopHeader extends StatelessWidget {
  const _BalanceDesktopHeader({
    required this.periodo,
    required this.onPeriodoChanged,
  });

  final BalancePeriodo periodo;
  final ValueChanged<BalancePeriodo> onPeriodoChanged;

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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Balance Financiero', style: AppTypography.h1),
              Text(
                'Ingresos, egresos y ganancias de la empresa',
                style: AppTypography.small.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const Spacer(),
          _PeriodoChips(selected: periodo, onChanged: onPeriodoChanged),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CHIPS DE PERÍODO
// ══════════════════════════════════════════════════════════════════════════════
class _PeriodoChips extends StatelessWidget {
  const _PeriodoChips({
    required this.selected,
    required this.onChanged,
  });

  final BalancePeriodo selected;
  final ValueChanged<BalancePeriodo> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      children: BalancePeriodo.values.map((p) {
        final isSelected = p == selected;
        return GestureDetector(
          onTap: () => onChanged(p),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary500 : AppColors.neutral100,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color:
                    isSelected ? AppColors.primary500 : AppColors.border,
              ),
            ),
            child: Text(
              p.label,
              style: AppTypography.small.copyWith(
                color: isSelected
                    ? AppColors.brandWhite
                    : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SECCIÓN DE 3 KPIs: Ingresos / Egresos / Ganancia Neta
// ══════════════════════════════════════════════════════════════════════════════
class _KpiSection extends ConsumerWidget {
  const _KpiSection({required this.periodo, required this.isMobile});

  final BalancePeriodo periodo;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumenAsync = ref.watch(balanceResumenProvider(periodo));

    return resumenAsync.when(
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => _ErrorBanner(mensaje: 'Error al cargar KPIs: $e'),
      data: (resumen) {
        final formatter = NumberFormat.currency(
          symbol: 'Bs. ',
          decimalDigits: 2,
          locale: 'es_BO',
        );

        final kpis = [
          _KpiData(
            label: 'INGRESOS',
            sublabel: 'Ventas del período',
            value: formatter.format(resumen.ingresosTotales),
            icon: Icons.trending_up_rounded,
            color: AppColors.success,
          ),
          _KpiData(
            label: 'EGRESOS PRODUCCIÓN',
            sublabel: 'Pagos a trabajadores',
            value: formatter.format(resumen.egresosTotales),
            icon: Icons.trending_down_rounded,
            color: const Color(0xFFD97706),
          ),
          _KpiData(
            label: 'GANANCIA NETA',
            sublabel: 'Ingresos − Egresos',
            value: formatter.format(resumen.balanceNeto),
            icon: Icons.account_balance_wallet_outlined,
            color: resumen.balanceNeto >= 0
                ? AppColors.info
                : AppColors.error,
          ),
        ];

        if (isMobile) {
          return Column(
            children: kpis
                .map((k) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _KpiCard(data: k),
                    ))
                .toList(),
          );
        }

        return Row(
          children: [
            for (var i = 0; i < kpis.length; i++) ...[
              Expanded(child: _KpiCard(data: kpis[i])),
              if (i < kpis.length - 1) const SizedBox(width: AppSpacing.lg),
            ],
          ],
        );
      },
    );
  }
}

class _KpiData {
  final String label;
  final String sublabel;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiData({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});
  final _KpiData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: data.color.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(data.icon, color: data.color, size: 22),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    data.value,
                    style: AppTypography.h3.copyWith(
                      fontWeight: FontWeight.w700,
                      color: data.color,
                    ),
                  ),
                ),
                Text(
                  data.sublabel,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// GRÁFICO DE BARRAS DOBLES — Ingresos vs Egresos por período
// ══════════════════════════════════════════════════════════════════════════════
class _GraficoBalanceCard extends ConsumerWidget {
  const _GraficoBalanceCard({required this.periodo, required this.isMobile});

  final BalancePeriodo periodo;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(balanceSeriesProvider(periodo));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
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
              const Icon(
                Icons.bar_chart_rounded,
                size: 18,
                color: AppColors.primary500,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Evolución Financiera', style: AppTypography.h3),
              const Spacer(),
              // Leyenda
              _LeyendaChip(color: AppColors.success, label: 'Ingresos'),
              const SizedBox(width: AppSpacing.md),
              _LeyendaChip(color: const Color(0xFFD97706), label: 'Egresos'),
              const SizedBox(width: AppSpacing.md),
              _LeyendaChip(color: AppColors.info, label: 'Ganancia'),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          seriesAsync.when(
            loading: () => const SizedBox(
              height: 180,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) =>
                _ErrorBanner(mensaje: 'Error al cargar gráfico: $e'),
            data: (series) => _BarChart(series: series, isMobile: isMobile),
          ),
        ],
      ),
    );
  }
}

class _LeyendaChip extends StatelessWidget {
  const _LeyendaChip({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.series, required this.isMobile});

  final List<BalanceDataPoint> series;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text('Sin datos en este período'),
        ),
      );
    }

    final maxVal = series
        .expand((s) => [s.ingresos, s.egresos])
        .fold<double>(1.0, (a, b) => math.max(a, b));
    const double maxBarHeight = 160.0;

    return SizedBox(
      height: 220,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: series.map((point) {
          final ingresosH = (point.ingresos / maxVal * maxBarHeight).clamp(2.0, maxBarHeight);
          final egresosH = (point.egresos / maxVal * maxBarHeight).clamp(2.0, maxBarHeight);
          final gananciaH = (point.ganancia.abs() / maxVal * maxBarHeight).clamp(2.0, maxBarHeight);
          final isGananciaPositiva = point.ganancia >= 0;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Etiqueta de ganancia
                  if (!isMobile)
                    Text(
                      point.ganancia >= 0
                          ? '+${point.ganancia.toStringAsFixed(0)}'
                          : point.ganancia.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: isGananciaPositiva ? AppColors.info : AppColors.error,
                      ),
                    ),
                  const SizedBox(height: 4),

                  // Las tres barras lado a lado
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Bar(height: ingresosH, color: AppColors.success),
                      const SizedBox(width: 2),
                      _Bar(height: egresosH, color: const Color(0xFFD97706)),
                      const SizedBox(width: 2),
                      _Bar(
                        height: gananciaH,
                        color: isGananciaPositiva ? AppColors.info : AppColors.error,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Etiqueta del eje X
                  Text(
                    point.label,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.color});
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TABLA DE ÓRDENES CON DETALLE FINANCIERO
// ══════════════════════════════════════════════════════════════════════════════
class _TablaOrdenesCard extends ConsumerWidget {
  const _TablaOrdenesCard({required this.periodo, required this.isMobile});

  final BalancePeriodo periodo;
  final bool isMobile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordenesAsync = ref.watch(balanceOrdenesProvider(periodo));

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera de la card
          Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 18,
                  color: AppColors.primary500,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('Detalle por Orden', style: AppTypography.h3),
                const Spacer(),
                ordenesAsync.whenData((ordenes) => Text(
                      '${ordenes.length} órdenes',
                      style: AppTypography.small.copyWith(
                        color: AppColors.textMuted,
                      ),
                    )).value ??
                    const SizedBox.shrink(),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Contenido
          ordenesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl2),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: _ErrorBanner(mensaje: 'Error al cargar órdenes: $e'),
            ),
            data: (ordenes) {
              if (ordenes.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl2),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 40,
                        color: AppColors.textMuted.withOpacity(0.3),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Sin órdenes en este período',
                        style: AppTypography.body
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isMobile)
                    _TablaOrdenMobile(ordenes: ordenes)
                  else
                    _TablaOrdenDesktop(ordenes: ordenes),
                  const Divider(height: 1, color: AppColors.border),
                  _SeccionCalculos(ordenes: ordenes, isMobile: isMobile),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Tabla Desktop ─────────────────────────────────────────────────────────────
class _TablaOrdenDesktop extends StatelessWidget {
  const _TablaOrdenDesktop({required this.ordenes});
  final List<OrdenBalanceModel> ordenes;

  @override
  Widget build(BuildContext context) {
    final formatter =
        NumberFormat.currency(symbol: 'Bs. ', decimalDigits: 2, locale: 'es_BO');

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          color: AppColors.neutral50,
          child: Row(
            children: [
              _th('ORDEN', flex: 2),
              _th('CLIENTE', flex: 3),
              _th('FECHA', flex: 2),
              _th('INGRESO', flex: 2),
              _th('COSTO PROD.', flex: 2),
              _th('GANANCIA', flex: 2),
              _th('MARGEN', flex: 1),
              _th('ESTADO PAGO', flex: 2),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),

        // Filas
        ...ordenes.asMap().entries.map((entry) {
          final i = entry.key;
          final o = entry.value;
          final margenColor = o.margenPorcentaje >= 30
              ? AppColors.success
              : o.margenPorcentaje >= 10
                  ? const Color(0xFFD97706)
                  : AppColors.error;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                child: Row(
                  children: [
                    // Orden
                    Expanded(
                      flex: 2,
                      child: Text(
                        o.numOrden.length > 8 ? o.numOrden.substring(0, 8).toUpperCase() : o.numOrden.toUpperCase(),
                        style: AppTypography.small.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary500,
                        ),
                      ),
                    ),
                    // Cliente
                    Expanded(
                      flex: 3,
                      child: Text(
                        o.clienteNombre,
                        style: AppTypography.small,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Fecha
                    Expanded(
                      flex: 2,
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(o.fechaOrden),
                        style: AppTypography.small.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    // Ingreso
                    Expanded(
                      flex: 2,
                      child: Text(
                        formatter.format(o.ingresoVenta),
                        style: AppTypography.small.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Costo producción
                    Expanded(
                      flex: 2,
                      child: Text(
                        formatter.format(o.costoProduccion),
                        style: AppTypography.small.copyWith(
                          color: const Color(0xFFD97706),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Ganancia
                    Expanded(
                      flex: 2,
                      child: Text(
                        formatter.format(o.ganancia),
                        style: AppTypography.small.copyWith(
                          color: o.ganancia >= 0 ? AppColors.info : AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    // Margen %
                    Expanded(
                      flex: 1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: margenColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          '${o.margenPorcentaje.toStringAsFixed(0)}%',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: margenColor,
                          ),
                        ),
                      ),
                    ),
                    // Estado pago
                    Expanded(
                      flex: 2,
                      child: _EstadoPagoBadge(estado: o.estadoPago),
                    ),
                  ],
                ),
              ),
              if (i < ordenes.length - 1)
                const Divider(height: 1, color: AppColors.border),
            ],
          );
        }),
      ],
    );
  }

  Widget _th(String label, {int flex = 1}) => Expanded(
        flex: flex,
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.4,
          ),
        ),
      );
}

// ── Tabla Mobile (cards apiladas) ─────────────────────────────────────────────
class _TablaOrdenMobile extends StatelessWidget {
  const _TablaOrdenMobile({required this.ordenes});
  final List<OrdenBalanceModel> ordenes;

  @override
  Widget build(BuildContext context) {
    final formatter =
        NumberFormat.currency(symbol: 'Bs. ', decimalDigits: 2, locale: 'es_BO');

    return Column(
      children: ordenes.map((o) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0,
          ),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.neutral50,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      o.numOrden.length > 8 ? o.numOrden.substring(0, 8).toUpperCase() : o.numOrden.toUpperCase(),
                      style: AppTypography.small.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary500,
                      ),
                    ),
                    _EstadoPagoBadge(estado: o.estadoPago),
                  ],
                ),
                Text(
                  o.clienteNombre,
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    _MiniKpi(
                      label: 'Ingreso',
                      value: formatter.format(o.ingresoVenta),
                      color: AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _MiniKpi(
                      label: 'Producción',
                      value: formatter.format(o.costoProduccion),
                      color: const Color(0xFFD97706),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    _MiniKpi(
                      label: 'Ganancia',
                      value: formatter.format(o.ganancia),
                      color:
                          o.ganancia >= 0 ? AppColors.info : AppColors.error,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MiniKpi extends StatelessWidget {
  const _MiniKpi({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: AppTypography.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            value,
            style: AppTypography.small.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BADGE DE ESTADO DE PAGO
// ══════════════════════════════════════════════════════════════════════════════
class _EstadoPagoBadge extends StatelessWidget {
  const _EstadoPagoBadge({required this.estado});
  final String estado;

  @override
  Widget build(BuildContext context) {
    final color = switch (estado.toLowerCase()) {
      'pagado' || 'paid' => AppColors.success,
      'pendiente' || 'pending' => const Color(0xFFD97706),
      'parcial' => AppColors.info,
      _ => AppColors.textMuted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        estado,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BANNER DE ERROR
// ══════════════════════════════════════════════════════════════════════════════
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.mensaje});
  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.errorBg,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              mensaje,
              style: AppTypography.caption.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SECCIÓN DE CÁLCULOS / SUMARIO DE BALANCES DE ÓRDENES
// ══════════════════════════════════════════════════════════════════════════════
class _SeccionCalculos extends StatelessWidget {
  const _SeccionCalculos({required this.ordenes, required this.isMobile});

  final List<OrdenBalanceModel> ordenes;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      symbol: 'Bs. ',
      decimalDigits: 2,
      locale: 'es_BO',
    );

    final totalOrdenes = ordenes.length;
    final totalIngresos = ordenes.fold<double>(0.0, (sum, o) => sum + o.ingresoVenta);
    final totalCostos = ordenes.fold<double>(0.0, (sum, o) => sum + o.costoProduccion);
    final totalGanancia = totalIngresos - totalCostos;
    final margenGeneral = totalIngresos > 0 ? (totalGanancia / totalIngresos) * 100 : 0.0;
    final ticketMedio = totalOrdenes > 0 ? totalIngresos / totalOrdenes : 0.0;

    final ordenesPagadas = ordenes.where((o) =>
        o.estadoPago.toLowerCase() == 'pagado' ||
        o.estadoPago.toLowerCase() == 'paid').length;
    final pctPagadas = totalOrdenes > 0 ? (ordenesPagadas / totalOrdenes) * 100 : 0.0;

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Resumen de Cálculos (Período)',
              style: AppTypography.small.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _buildCalcRow('Total Órdenes', '$totalOrdenes ($ordenesPagadas pagadas, ${pctPagadas.toStringAsFixed(0)}%)'),
            _buildCalcRow('Total Ingresos (Ventas)', currencyFormatter.format(totalIngresos), valueColor: AppColors.success),
            _buildCalcRow('Total Costos (Mano de Obra)', currencyFormatter.format(totalCostos), valueColor: const Color(0xFFD97706)),
            _buildCalcRow('Ganancia Bruta', currencyFormatter.format(totalGanancia), valueColor: totalGanancia >= 0 ? AppColors.info : AppColors.error, isBoldValue: true),
            _buildCalcRow('Margen de Rentabilidad', '${margenGeneral.toStringAsFixed(1)}%', valueColor: margenGeneral >= 0 ? AppColors.info : AppColors.error),
            _buildCalcRow('Ticket Medio (Venta/Orden)', currencyFormatter.format(ticketMedio)),
          ],
        ),
      );
    }

    return Container(
      color: AppColors.neutral50,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calculate_outlined,
                size: 18,
                color: AppColors.primary500,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Resumen de Cálculos y Rentabilidad del Período',
                style: AppTypography.small.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _buildCalcCard(
                  label: 'TOTAL ÓRDENES',
                  value: '$totalOrdenes',
                  subtext: '$ordenesPagadas pagadas (${pctPagadas.toStringAsFixed(0)}%)',
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.primary500,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildCalcCard(
                  label: 'TOTAL INGRESOS',
                  value: currencyFormatter.format(totalIngresos),
                  subtext: 'Venta de todas las órdenes',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildCalcCard(
                  label: 'TOTAL COSTOS',
                  value: currencyFormatter.format(totalCostos),
                  subtext: 'Mano de obra y producción',
                  icon: Icons.trending_down_rounded,
                  color: const Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildCalcCard(
                  label: 'GANANCIA DEL PERÍODO',
                  value: currencyFormatter.format(totalGanancia),
                  subtext: 'Ingreso − Egreso de órdenes',
                  icon: Icons.account_balance_wallet_outlined,
                  color: totalGanancia >= 0 ? AppColors.info : AppColors.error,
                  highlight: true,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _buildCalcCard(
                  label: 'MARGEN / TICKET MEDIO',
                  value: '${margenGeneral.toStringAsFixed(1)}%',
                  subtext: 'Ticket medio: ${currencyFormatter.format(ticketMedio)}',
                  icon: Icons.pie_chart_outline_rounded,
                  color: margenGeneral >= 30
                      ? AppColors.success
                      : margenGeneral >= 10
                          ? const Color(0xFFD97706)
                          : AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalcRow(String label, String value, {Color? valueColor, bool isBoldValue = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: AppTypography.small.copyWith(
              fontWeight: isBoldValue ? FontWeight.bold : FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalcCard({
    required String label,
    required String value,
    required String subtext,
    required IconData icon,
    required Color color,
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: highlight ? color.withOpacity(0.05) : AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: highlight ? color.withOpacity(0.3) : AppColors.border,
          width: highlight ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtext,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
