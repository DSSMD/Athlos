// lib/presentation/providers/balance_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/services/balance_service.dart';
import '../../domain/models/balance_model.dart';

// ── Instancia del servicio ────────────────────────────────────────────────────
final balanceServiceProvider = Provider<BalanceService>((ref) => BalanceService());

// ── Período activo seleccionado por el usuario ────────────────────────────────
final balancePeriodoProvider = StateProvider<BalancePeriodo>(
  (ref) => BalancePeriodo.mes,
);

// ── Resumen de KPIs (Ingresos / Egresos / Balance Neto) ──────────────────────
final balanceResumenProvider =
    FutureProvider.family<ResumenBalanceModel, BalancePeriodo>(
  (ref, periodo) async {
    final service = ref.read(balanceServiceProvider);
    final desde = periodo.fechaDesde;
    return service.getResumenBalance(desde: desde);
  },
);

// ── Tabla de órdenes con costos de producción ────────────────────────────────
final balanceOrdenesProvider =
    FutureProvider.family<List<OrdenBalanceModel>, BalancePeriodo>(
  (ref, periodo) async {
    final service = ref.read(balanceServiceProvider);
    final desde = periodo.fechaDesde;
    return service.getOrdenesConBalance(desde: desde);
  },
);

// ── Series históricas para el gráfico de barras dobles ───────────────────────
final balanceSeriesProvider =
    FutureProvider.family<List<BalanceDataPoint>, BalancePeriodo>(
  (ref, periodo) async {
    final service = ref.read(balanceServiceProvider);
    return service.getSeriesHistoricas(periodo);
  },
);
