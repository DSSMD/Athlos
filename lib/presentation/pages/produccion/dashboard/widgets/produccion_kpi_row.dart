// ============================================================================
// produccion_kpi_row.dart
// Ubicación: lib/presentation/pages/produccion/dashboard/widgets/produccion_kpi_row.dart
// Descripción: Fila de 4 KPIs derivados de ordenesProvider para la tab
// "Métricas" del dashboard de producción.
//
// KPIs:
//   - Pendientes:     count(idEstado == 1)
//   - En Producción:  count(idEstado == 2)
//   - Finalizadas:    count(idEstado == 3)
//   - Con Retraso:    count(idEstado != 4 && fechaEntrega < hoy)
//
// El KPI "Con Retraso" se pinta en rojo (AppColors.error) sólo cuando hay
// al menos una orden retrasada. Cuando no hay, queda en color neutro para
// no generar ruido visual.
//
// Layout responsive: Row con 4 Expanded en desktop, GridView 2x2 en mobile.
//
// Estados del AsyncValue:
//   - loading → valor "..." en las 4 cards.
//   - error   → valor "—" en las 4 cards (no se colorea retraso).
//   - data    → counts reales.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/models/orden_model.dart';
import '../../../../providers/orden_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/breakpoints.dart';
import '../../../../widgets/users/kpi_card.dart';

class ProduccionKpiRow extends ConsumerWidget {
  const ProduccionKpiRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordenesAsync = ref.watch(ordenesProvider);
    final isMobile = context.isMobile;

    return ordenesAsync.when(
      loading: () => _KpiGrid(
        isMobile: isMobile,
        cards: _placeholderCards(valueText: '...'),
      ),
      error: (_, _) => _KpiGrid(
        isMobile: isMobile,
        cards: _placeholderCards(valueText: '—'),
      ),
      data: (ordenes) =>
          _KpiGrid(isMobile: isMobile, cards: _kpisFromData(ordenes)),
    );
  }

  // ─── Cálculo de KPIs sobre la lista real ───────────────────────────────────

  List<KpiCard> _kpisFromData(List<OrdenModel> ordenes) {
    final now = DateTime.now();

    final int pendientes = ordenes.where((o) => o.idEstado == 1).length;
    final int enProduccion = ordenes.where((o) => o.idEstado == 2).length;
    final int finalizadas = ordenes.where((o) => o.idEstado == 3).length;
    final int conRetraso = ordenes
        .where((o) => o.idEstado != 4 && o.fechaEntrega.isBefore(now))
        .length;

    return [
      KpiCard(
        value: '$pendientes',
        label: 'Pendientes',
        description: 'Esperando producción',
      ),
      KpiCard(
        value: '$enProduccion',
        label: 'En Producción',
        description: 'En taller actualmente',
      ),
      KpiCard(
        value: '$finalizadas',
        label: 'Finalizadas',
        description: 'Listas para entregar',
      ),
      KpiCard(
        value: '$conRetraso',
        label: 'Con Retraso',
        description: conRetraso > 0
            ? 'Fecha de entrega vencida'
            : 'Todo dentro de fecha',
        // Sólo coloreamos rojo cuando hay retrasos para no asustar
        // visualmente cuando todo está al día.
        valueColor: conRetraso > 0 ? AppColors.error : null,
      ),
    ];
  }

  // ─── Placeholders para loading / error ─────────────────────────────────────

  List<KpiCard> _placeholderCards({required String valueText}) => [
    KpiCard(
      value: valueText,
      label: 'Pendientes',
      description: 'Esperando producción',
    ),
    KpiCard(
      value: valueText,
      label: 'En Producción',
      description: 'En taller actualmente',
    ),
    KpiCard(
      value: valueText,
      label: 'Finalizadas',
      description: 'Listas para entregar',
    ),
    KpiCard(
      value: valueText,
      label: 'Con Retraso',
      description: 'Fecha de entrega vencida',
    ),
  ];
}

// ═════════════════════════════════════════════════════════════════════════════
// GRID — responsive 4xRow desktop / 2x2 mobile
// ═════════════════════════════════════════════════════════════════════════════
class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.isMobile, required this.cards});

  final bool isMobile;
  final List<KpiCard> cards;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        // 1.4 da cards proporcionadas para KpiCard (h1 value + label +
        // description) en pantallas mobile típicas sin recortar texto.
        childAspectRatio: 1.4,
        children: cards,
      );
    }

    // IntrinsicHeight: la fila vive dentro de un SingleChildScrollView con
    // altura unbounded, y CrossAxisAlignment.stretch sin esto le pide
    // altura infinita al Row. IntrinsicHeight mide la card más alta y le
    // pasa esa altura al Row para que el stretch funcione acotado.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            Expanded(child: cards[i]),
            if (i < cards.length - 1) const SizedBox(width: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}
