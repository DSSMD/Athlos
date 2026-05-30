// lib/presentation/components/ordenes/orden_produccion_pagos_card.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../providers/pago_provider.dart';
import '../../components/produccion/pago_trabajador_dialog.dart';
import '../../../domain/models/pago_trabajador_model.dart';

// TODO:(PAGOS) Asegúrate de haber creado la VIEW vista_pagos_produccion_por_orden
// en Supabase antes de usar este componente. Ver el SQL en el implementation_plan.md

/// Card que muestra el resumen de pagos a producción de una orden.
/// Consulta la VIEW [vista_pagos_produccion_por_orden] a través de [resumenPagosOrdenProvider].
/// Se agrega en [OrdenDetallePage] debajo de la card de historial.
class OrdenProduccionPagosCard extends ConsumerWidget {
  final String numOrden;

  const OrdenProduccionPagosCard({super.key, required this.numOrden});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumenAsync = ref.watch(resumenPagosOrdenProvider(numOrden));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Título ──────────────────────────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.engineering_outlined,
                size: 18,
                color: AppColors.primary500,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text('Pagos a Producción', style: AppTypography.h3),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Contenido ───────────────────────────────────────────────────
          resumenAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                // TODO:(PAGOS) Si aparece "relation does not exist", la VIEW no fue creada en Supabase.
                'Error al cargar: $e',
                style: AppTypography.small.copyWith(color: AppColors.error),
              ),
            ),
            data: (resumen) {
              if (resumen.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Column(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 36,
                        color: AppColors.textMuted.withOpacity(0.4),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Sin trabajadores asignados aún.',
                        style: AppTypography.small.copyWith(
                          color: AppColors.textMuted,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              // ── Totales globales de la orden ───────────────────────────
              final totalPactado =
                  resumen.fold<double>(0, (s, r) => s + r.totalPactado);
              final totalPagado =
                  resumen.fold<double>(0, (s, r) => s + r.totalAdelantos);
              final saldoTotal = totalPactado - totalPagado;

              return Column(
                children: [
                  // Resumen global en 3 KPIs compactos
                  _GlobalKpis(
                    totalPactado: totalPactado,
                    totalPagado: totalPagado,
                    saldoTotal: saldoTotal,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Divider(height: 1, color: AppColors.border),
                  const SizedBox(height: AppSpacing.md),

                  // Fila por cada trabajador
                  ...resumen.map(
                    (r) => _TrabajadorPagoRow(
                      resumen: r,
                      numOrden: numOrden,
                      onPagoRegistrado: () {
                        ref.invalidate(resumenPagosOrdenProvider(numOrden));
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// 3 KPIs compactos: Pactado / Pagado / Saldo
// ══════════════════════════════════════════════════════════════════════════════
class _GlobalKpis extends StatelessWidget {
  final double totalPactado;
  final double totalPagado;
  final double saldoTotal;

  const _GlobalKpis({
    required this.totalPactado,
    required this.totalPagado,
    required this.saldoTotal,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _KpiChip(
          label: 'Pactado',
          value: 'Bs. ${totalPactado.toStringAsFixed(2)}',
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.sm),
        _KpiChip(
          label: 'Pagado',
          value: 'Bs. ${totalPagado.toStringAsFixed(2)}',
          color: const Color(0xFF16A34A),
        ),
        const SizedBox(width: AppSpacing.sm),
        _KpiChip(
          label: 'Saldo',
          value: 'Bs. ${saldoTotal.toStringAsFixed(2)}',
          color: saldoTotal <= 0
              ? const Color(0xFF16A34A)
              : const Color(0xFFD97706),
        ),
      ],
    );
  }
}

class _KpiChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _KpiChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 9,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: AppTypography.small.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Fila individual por trabajador
// ══════════════════════════════════════════════════════════════════════════════
class _TrabajadorPagoRow extends StatelessWidget {
  final ResumenPagoProduccionModel resumen;
  final String numOrden;
  final VoidCallback onPagoRegistrado;

  const _TrabajadorPagoRow({
    required this.resumen,
    required this.numOrden,
    required this.onPagoRegistrado,
  });

  @override
  Widget build(BuildContext context) {
    final Color estadoColor = switch (resumen.estadoPagoGlobal) {
      'Liquidado' => const Color(0xFF16A34A),
      'Con Adelantos' => const Color(0xFF2563EB),
      _ => const Color(0xFFD97706),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.neutral50,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabecera: Nombre + badge de estado ──────────────────────
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary500.withOpacity(0.1),
                  child: Text(
                    resumen.trabajadorNombre.isNotEmpty
                        ? resumen.trabajadorNombre[0].toUpperCase()
                        : '?',
                    style: AppTypography.small.copyWith(
                      color: AppColors.primary500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resumen.trabajadorNombre,
                        style: AppTypography.small.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${resumen.area} · ${resumen.lotesAsignados} lote${resumen.lotesAsignados != 1 ? 's' : ''}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Badge de estado global
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: estadoColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    resumen.estadoPagoGlobal,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: estadoColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),

            // ── Montos ───────────────────────────────────────────────────
            Row(
              children: [
                _MontoItem(
                  label: 'Pactado',
                  value: resumen.totalPactado,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.md),
                _MontoItem(
                  label: 'Pagado',
                  value: resumen.totalAdelantos,
                  color: const Color(0xFF16A34A),
                ),
                const SizedBox(width: AppSpacing.md),
                _MontoItem(
                  label: 'Saldo',
                  value: resumen.saldoPendiente,
                  color: resumen.saldoPendiente <= 0
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFD97706),
                ),
                // Botón pagar (solo si hay saldo pendiente)
                if (resumen.estadoPagoGlobal != 'Liquidado') ...[
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () async {
                      final pagado = await showDialog<bool>(
                        context: context,
                        builder: (_) => PagoTrabajadorDialog(
                          idTrabajador: resumen.idTrabajador,
                          nombreTrabajador: resumen.trabajadorNombre,
                          numOrden: numOrden,
                          saldoPendiente: resumen.saldoPendiente,
                        ),
                      );
                      if (pagado == true) onPagoRegistrado();
                    },
                    icon: const Icon(Icons.add_card_outlined, size: 16),
                    label: const Text('Pagar'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary500,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MontoItem extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MontoItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        Text(
          'Bs. ${value.toStringAsFixed(2)}',
          style: AppTypography.small.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
