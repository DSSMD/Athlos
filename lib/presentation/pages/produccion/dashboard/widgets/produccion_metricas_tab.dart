// ============================================================================
// produccion_metricas_tab.dart
// Ubicación: lib/presentation/pages/produccion/dashboard/widgets/produccion_metricas_tab.dart
// Descripción: Agrupa los componentes de la tab "Métricas" del dashboard de
// producción: fila de KPIs + lista de pedidos en producción activa.
// ============================================================================

import 'package:flutter/material.dart';

import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import 'produccion_estado_chart.dart';
import 'produccion_kpi_row.dart';
import 'produccion_pedidos_lista.dart';

class ProduccionMetricasTab extends StatelessWidget {
  const ProduccionMetricasTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const ProduccionKpiRow(),
          const SizedBox(height: AppSpacing.lg),
          const ProduccionEstadoChart(),
          const SizedBox(height: AppSpacing.lg),
          Text('Pedidos en producción', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.md),
          const ProduccionPedidosLista(),
        ],
      ),
    );
  }
}
