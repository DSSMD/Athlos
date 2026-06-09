// ============================================================================
// lib/presentation/pages/produccion/scheduling/scheduling_page.dart
// ============================================================================
// Página consultiva del módulo de Scheduling (Moore-Hodgson).
// Solo lectura — muestra la secuencia óptima calculada y cuántas órdenes
// llegarán tarde. No permite modificar el schedule ni las órdenes.
//
// Estructura:
//   [Header: botón "Recalcular" + fecha del último cálculo]
//   [KPIs: Total órdenes / A tiempo / Con retraso / % Puntualidad]
//   [Tabla de secuencia con badge rojo para órdenes tardías]
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../domain/models/scheduling_model.dart';
import '../../../providers/scheduling_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../../widgets/users/kpi_card.dart';
import '../../../widgets/shared/empty_state.dart';

class SchedulingPage extends ConsumerWidget {
  const SchedulingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schedulingAsync = ref.watch(schedulingStateProvider);
    final resumen = ref.watch(schedulingResumenProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        return Column(
          children: [
            // ── HEADER ──────────────────────────────────────────────────────
            _SchedulingHeader(
              resumen: resumen,
              isLoading: schedulingAsync.isLoading,
              onRecalcular: () =>
                  ref.read(schedulingStateProvider.notifier).calcular(),
            ),
            // ── BODY ────────────────────────────────────────────────────────
            Expanded(
              child: schedulingAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Error al calcular el scheduling',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        e.toString().replaceFirst('Exception: ', ''),
                        style: AppTypography.small.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FilledButton.icon(
                        onPressed: () => ref
                            .read(schedulingStateProvider.notifier)
                            .calcular(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Intentar nuevamente'),
                      ),
                    ],
                  ),
                ),
                data: (resultados) {
                  if (resultados.isEmpty) {
                    return _EmptyScheduling(
                      onRecalcular: () =>
                          ref.read(schedulingStateProvider.notifier).calcular(),
                    );
                  }
                  return SingleChildScrollView(
                    padding: EdgeInsets.all(
                      isMobile ? AppSpacing.lg : AppSpacing.xl2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // KPIs
                        if (resumen != null)
                          _KpiRow(resumen: resumen, isMobile: isMobile),
                        const SizedBox(height: AppSpacing.xl),
                        // Aviso informativo
                        _InfoBanner(),
                        const SizedBox(height: AppSpacing.lg),
                        // Tabla de resultados
                        isMobile
                            ? _MobileList(resultados: resultados)
                            : _DesktopTable(resultados: resultados),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// HEADER
// ════════════════════════════════════════════════════════════════════════════

class _SchedulingHeader extends StatelessWidget {
  const _SchedulingHeader({
    required this.resumen,
    required this.isLoading,
    required this.onRecalcular,
  });

  final SchedulingResumen? resumen;
  final bool isLoading;
  final VoidCallback onRecalcular;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl2,
        vertical: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Secuenciación de Órdenes', style: AppTypography.h2),
                const SizedBox(height: 2),
                Text(
                  resumen != null
                      ? 'Último cálculo: ${DateFormat('dd/MM/yyyy HH:mm').format(resumen!.fechaCalculo)}'
                      : 'Ejecutá el cálculo para ver la secuencia óptima',
                  style: AppTypography.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.icon(
            onPressed: isLoading ? null : onRecalcular,
            style: TextButton.styleFrom(backgroundColor: AppColors.primary500, foregroundColor: Colors.white),
            icon: isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary500
                    ),
                  )
                : const Icon(Icons.calculate_outlined, size: 18),
            label: Text(isLoading ? 'Calculando...' : 'Recalcular'),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// KPI ROW
// ════════════════════════════════════════════════════════════════════════════

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.resumen, required this.isMobile});

  final SchedulingResumen resumen;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final cards = [
      KpiCard(
        value: '${resumen.totalOrdenes}',
        label: 'Total',
        description: 'Órdenes activas',
      ),
      KpiCard(
        value: '${resumen.ordenesEnTiempo}',
        label: 'A tiempo',
        description: 'Se entregarán puntual',
        valueColor: AppColors.success,
      ),
      KpiCard(
        value: '${resumen.ordenesConRetraso}',
        label: 'Con retraso',
        description: 'No llegarán a la fecha',
        valueColor: resumen.ordenesConRetraso > 0
            ? AppColors.error
            : AppColors.textMuted,
      ),
      KpiCard(
        value: '${resumen.porcentajeEnTiempo.toStringAsFixed(0)}%',
        label: 'Puntualidad',
        description: 'Órdenes en tiempo',
        valueColor: resumen.porcentajeEnTiempo >= 80
            ? AppColors.success
            : AppColors.warning,
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[0]),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: cards[1]),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: cards[2]),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: cards[3]),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          Expanded(child: cards[i]),
          if (i < cards.length - 1) const SizedBox(width: AppSpacing.lg),
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// BANNER INFORMATIVO
// ════════════════════════════════════════════════════════════════════════════

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.info),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Esta es una vista consultiva. El orden de producción sugerido '
              'minimiza el número de entregas tardías (algoritmo Moore-Hodgson). '
              'Los tiempos son estimaciones basadas en el tiempo de producción '
              'configurado en cada plantilla y la capacidad de 8 h/día del taller.',
              style: AppTypography.small.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// EMPTY STATE
// ════════════════════════════════════════════════════════════════════════════

class _EmptyScheduling extends StatelessWidget {
  const _EmptyScheduling({required this.onRecalcular});
  final VoidCallback onRecalcular;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const EmptyState(
            icon: Icons.schedule_outlined,
            title: 'Sin datos de scheduling',
            subtitle:
                'Ejecutá el cálculo para ver la secuencia óptima de producción.',
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton.icon(
            onPressed: onRecalcular,
            style: TextButton.styleFrom(backgroundColor: AppColors.primary500, foregroundColor: Colors.white),
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Calcular ahora'),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// DESKTOP TABLE
// ════════════════════════════════════════════════════════════════════════════

class _DesktopTable extends StatelessWidget {
  const _DesktopTable({required this.resultados});
  final List<OrdenSchedulingResult> resultados;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: const [
                _HCol('#', flex: 1),
                _HCol('ORDEN / CLIENTE', flex: 4),
                _HCol('PRIORIDAD', flex: 2),
                _HCol('ENTREGA', flex: 2),
                _HCol('FIN EST.', flex: 2),
                _HCol('TIEMPO (h)', flex: 2),
                _HCol('ESTADO', flex: 2),
              ],
            ),
          ),
          // Filas
          for (var i = 0; i < resultados.length; i++) ...[
            _DesktopRow(result: resultados[i]),
            if (i < resultados.length - 1)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

class _HCol extends StatelessWidget {
  const _HCol(this.label, {required this.flex});
  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
}

class _DesktopRow extends StatelessWidget {
  const _DesktopRow({required this.result});
  final OrdenSchedulingResult result;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yy');
    final enTiempo = result.enTiempo;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // Posición
          Expanded(
            flex: 1,
            child: Text(
              '${result.posicionSecuencia}',
              style: AppTypography.small.copyWith(
                color: AppColors.textMuted,
                fontFamily: 'monospace',
              ),
            ),
          ),
          // Orden / Cliente
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.numOrden.substring(0, 8).toUpperCase(),
                  style: AppTypography.small.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  result.clienteNombre,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Prioridad
          Expanded(
            flex: 2,
            child: _PrioridadBadge(prioridad: result.prioridad),
          ),
          // Fecha entrega (due date)
          Expanded(
            flex: 2,
            child: Text(
              fmt.format(result.fechaEntrega),
              style: AppTypography.small.copyWith(
                color: enTiempo ? AppColors.textPrimary : AppColors.error,
                fontWeight: enTiempo ? FontWeight.w400 : FontWeight.w600,
              ),
            ),
          ),
          // Fecha fin estimada
          Expanded(
            flex: 2,
            child: Text(
              fmt.format(result.fechaFinEstimada),
              style: AppTypography.small.copyWith(
                color: enTiempo ? AppColors.textSecondary : AppColors.error,
              ),
            ),
          ),
          // Tiempo proceso
          Expanded(
            flex: 2,
            child: Text(
              result.tiempoProceso == 0
                  ? '—'
                  : '${result.tiempoProceso.toStringAsFixed(1)} h',
              style: AppTypography.small.copyWith(
                color: AppColors.textSecondary,
                fontFamily: 'monospace',
              ),
            ),
          ),
          // Estado en-tiempo / tarde
          Expanded(flex: 2, child: _EstadoBadge(enTiempo: enTiempo)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// MOBILE LIST
// ════════════════════════════════════════════════════════════════════════════

class _MobileList extends StatelessWidget {
  const _MobileList({required this.resultados});
  final List<OrdenSchedulingResult> resultados;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < resultados.length; i++) ...[
          _MobileCard(result: resultados[i]),
          if (i < resultados.length - 1) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _MobileCard extends StatelessWidget {
  const _MobileCard({required this.result});
  final OrdenSchedulingResult result;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd/MM/yy');
    final enTiempo = result.enTiempo;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: enTiempo
              ? AppColors.border
              : AppColors.error.withValues(alpha: 0.4),
          width: enTiempo ? 1 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: enTiempo
                      ? AppColors.primary500.withValues(alpha: 0.15)
                      : AppColors.error.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${result.posicionSecuencia}',
                  style: AppTypography.small.copyWith(
                    color: enTiempo ? AppColors.primary500 : AppColors.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.numOrden.substring(0, 8).toUpperCase(),
                      style: AppTypography.small.copyWith(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      result.clienteNombre,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _EstadoBadge(enTiempo: enTiempo),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _InfoChip(label: 'Prioridad', value: result.prioridad),
              const SizedBox(width: AppSpacing.sm),
              _InfoChip(
                label: 'Entrega',
                value: fmt.format(result.fechaEntrega),
                valueColor: enTiempo ? null : AppColors.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              _InfoChip(
                label: 'Fin est.',
                value: fmt.format(result.fechaFinEstimada),
              ),
              if (result.tiempoProceso > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                _InfoChip(
                  label: 'Tiempo',
                  value: '${result.tiempoProceso.toStringAsFixed(1)} h',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.value, this.valueColor});
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        ),
        Text(
          value,
          style: AppTypography.small.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// BADGES COMPARTIDOS
// ════════════════════════════════════════════════════════════════════════════

class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({required this.enTiempo});
  final bool enTiempo;

  @override
  Widget build(BuildContext context) {
    final color = enTiempo ? AppColors.success : AppColors.error;
    final label = enTiempo ? 'A tiempo' : 'Con retraso';
    final icon = enTiempo ? Icons.check_circle_outline : Icons.warning_amber;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _PrioridadBadge extends StatelessWidget {
  const _PrioridadBadge({required this.prioridad});
  final String prioridad;

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (prioridad.toLowerCase()) {
      case 'urgente':
        color = AppColors.error;
        break;
      case 'alta':
        color = AppColors.warning;
        break;
      default:
        color = AppColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        prioridad.isEmpty ? 'Normal' : _capitalize(prioridad),
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
