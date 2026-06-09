// ============================================================================
// ventas_dashboard_page.dart
// Ubicación: lib/presentation/pages/cajas/dashboard/ventas_dashboard_page.dart
// Descripción: Dashboard de ventas para el rol cajas (SCRUM-97 / HU-20).
//
// Sigue las convenciones del dashboard de administración
// (admin/dashboard/dashboard_page.dart):
//   - ConsumerStatefulWidget, header diferenciado por breakpoint
//     (MobileScreenHeader en mobile / header propio en desktop),
//   - sin Scaffold propio (lo provee el shell MainLayout),
//   - datos REALES consumidos en tiempo real de los providers de Supabase
//     (ordenesProvider, clientesProvider) y métricas calculadas client-side.
//
// Página standalone: el enganche en la ruta /ventas se coordina aparte.
// Moneda unificada en "Bs." según requerimiento del cliente.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../theme/breakpoints.dart';
import '../../../widgets/shared/mobile_screen_header.dart';

import '../../../providers/orden_provider.dart';
import '../../../providers/cliente_provider.dart';

import '../../../../domain/models/orden_model.dart';
import '../../../../domain/models/cliente_model.dart';

import 'widgets/ventas_kpi_row.dart';
import 'widgets/ventas_bar_chart.dart';
import 'widgets/ventas_ordenes_recientes.dart';
import 'widgets/ventas_deudores.dart';

class VentasDashboardPage extends ConsumerStatefulWidget {
  const VentasDashboardPage({super.key});

  @override
  ConsumerState<VentasDashboardPage> createState() =>
      _VentasDashboardPageState();
}

class _VentasDashboardPageState extends ConsumerState<VentasDashboardPage> {
  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    // --- Consumo reactivo de Supabase (sin mock) ---
    final ordenesAsync = ref.watch(ordenesProvider);
    final clientesAsync = ref.watch(clientesProvider);

    final isLoading =
        ordenesAsync.isLoading && (ordenesAsync.value?.isEmpty ?? true);

    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl2),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final ordenes = ordenesAsync.value ?? const <OrdenModel>[];
    final clientes = clientesAsync.value ?? const <ClienteModel>[];

    // --- KPIs en tiempo real (client-side) ---
    final double totalVentas =
        ordenes.fold<double>(0, (sum, o) => sum + o.costoTotal);
    final int pedidosRealizados = ordenes.length;
    final int pedidosPendientes =
        ordenes.where((o) => o.idEstado == 1).length;
    final double deudaPorCobrar =
        clientes.fold<double>(0, (sum, c) => sum + c.deudaTotal);

    return Column(
      children: [
        if (isMobile)
          MobileScreenHeader(
            title: 'Ventas',
            bottom: Text(
              'Resumen del mes — ${DateFormat('MMMM yyyy', 'es').format(DateTime.now())}',
              style: AppTypography.small.copyWith(
                color: AppColors.brandWhite.withValues(alpha: 0.7),
              ),
            ),
          )
        else
          const _DesktopHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding:
                EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VentasKpiRow(
                  isMobile: isMobile,
                  totalVentas: totalVentas,
                  pedidosRealizados: pedidosRealizados,
                  pedidosPendientes: pedidosPendientes,
                  deudaPorCobrar: deudaPorCobrar,
                ),
                const SizedBox(height: AppSpacing.lg),
                VentasBarChart(ordenes: ordenes),
                const SizedBox(height: AppSpacing.lg),
                _BottomSplit(
                  isMobile: isMobile,
                  ordenes: ordenes,
                  clientes: clientes,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HEADER DESKTOP — título + tagline (mismo estilo que el dashboard de admin)
// ═════════════════════════════════════════════════════════════════════════════
class _DesktopHeader extends StatelessWidget {
  const _DesktopHeader();

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
          Text('Dashboard de Ventas', style: AppTypography.h1),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SECCIÓN INFERIOR — pedidos recientes + clientes con deuda
// ═════════════════════════════════════════════════════════════════════════════
class _BottomSplit extends StatelessWidget {
  const _BottomSplit({
    required this.isMobile,
    required this.ordenes,
    required this.clientes,
  });

  final bool isMobile;
  final List<OrdenModel> ordenes;
  final List<ClienteModel> clientes;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return Column(
        children: [
          VentasOrdenesRecientes(ordenes: ordenes),
          const SizedBox(height: AppSpacing.lg),
          VentasDeudores(clientes: clientes),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: VentasOrdenesRecientes(ordenes: ordenes)),
        const SizedBox(width: AppSpacing.lg),
        Expanded(flex: 1, child: VentasDeudores(clientes: clientes)),
      ],
    );
  }
}
