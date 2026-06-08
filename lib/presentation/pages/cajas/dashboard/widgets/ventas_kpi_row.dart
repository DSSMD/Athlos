// ============================================================================
// ventas_kpi_row.dart
// Fila de KPIs del dashboard de ventas (rol cajas).
// Grid 2x2 en mobile / 4 columnas en desktop, mismo patrón que el dashboard
// de administración (admin/dashboard/dashboard_page.dart).
// Datos calculados client-side en la página a partir de ordenesProvider y
// clientesProvider; este widget solo presenta.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';

class VentasKpiRow extends StatelessWidget {
  const VentasKpiRow({
    super.key,
    required this.isMobile,
    required this.totalVentas,
    required this.pedidosRealizados,
    required this.pedidosPendientes,
    required this.deudaPorCobrar,
  });

  final bool isMobile;
  final double totalVentas;
  final int pedidosRealizados;
  final int pedidosPendientes;
  final double deudaPorCobrar;

  @override
  Widget build(BuildContext context) {
    final moneda =
        NumberFormat.currency(symbol: 'Bs. ', decimalDigits: 0, locale: 'es_BO');

    final kpis = <_KpiData>[
      _KpiData(
        label: 'TOTAL DE VENTAS',
        value: moneda.format(totalVentas),
        delta: 'Ingresos acumulados',
        deltaColor: AppColors.success,
      ),
      _KpiData(
        label: 'PEDIDOS REALIZADOS',
        value: '$pedidosRealizados',
        delta: 'Órdenes registradas',
        deltaColor: AppColors.primary500,
      ),
      _KpiData(
        label: 'PEDIDOS PENDIENTES',
        value: '$pedidosPendientes',
        delta: pedidosPendientes > 0 ? 'Por iniciar producción' : 'Sin pendientes',
        deltaColor: pedidosPendientes > 0 ? Colors.orange : AppColors.success,
      ),
      _KpiData(
        label: 'DEUDA POR COBRAR',
        value: moneda.format(deudaPorCobrar),
        delta: deudaPorCobrar > 0 ? 'Saldo de clientes' : 'Todo cobrado',
        deltaColor: deudaPorCobrar > 0 ? AppColors.error : AppColors.success,
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
        children: kpis.map((k) => _KpiCard(data: k)).toList(),
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
  }
}

class _KpiData {
  const _KpiData({
    required this.label,
    required this.value,
    required this.delta,
    required this.deltaColor,
  });

  final String label;
  final String value;
  final String delta;
  final Color deltaColor;
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.data});
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
            style: AppTypography.caption
                .copyWith(color: data.deltaColor, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
