// ============================================================================
// cliente_summary_panel.dart
// Ubicación: lib/presentation/components/clientes/cliente_summary_panel.dart
// Descripción: Panel lateral derecho con avatar del cliente, badges, resumen
// financiero y últimas órdenes. Solo visible en modo "Editar cliente".
// ============================================================================

import 'package:flutter/material.dart';
import '../../models/cliente_mock.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '_section_card.dart';

class ClienteSummaryPanel extends StatelessWidget {
  const ClienteSummaryPanel({super.key, required this.cliente});

  final ClienteMock cliente;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ClienteHeaderCard(cliente: cliente),
        const SizedBox(height: AppSpacing.lg),
        _ResumenFinancieroCard(cliente: cliente),
        const SizedBox(height: AppSpacing.lg),
        _UltimasOrdenesCard(cliente: cliente),
      ],
    );
  }
}

// ─────────────────────────────────────────────── HEADER CON AVATAR ──

class _ClienteHeaderCard extends StatelessWidget {
  const _ClienteHeaderCard({required this.cliente});
  final ClienteMock cliente;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.brandWhite,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Avatar con iniciales
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: AppColors.primary500,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              cliente.iniciales,
              style: AppTypography.h2.copyWith(
                color: AppColors.brandWhite,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Nombre
          Text(
            cliente.nombreCorto,
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
            textAlign: TextAlign.center,
          ),
          if (cliente.razonSocial != null) ...[
            const SizedBox(height: 2),
            Text(
              cliente.razonSocial!,
              style: AppTypography.small.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          // Badges: Activo / N órdenes / Prioritario
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _MiniBadge(
                label: cliente.activo ? 'Activo' : 'Inactivo',
                bg: cliente.activo ? AppColors.successBg : AppColors.errorBg,
                fg: cliente.activo ? AppColors.success : AppColors.error,
              ),
              _MiniBadge(
                label: '${cliente.cantidadOrdenes} órdenes',
                bg: AppColors.infoBg,
                fg: AppColors.info,
              ),
              if (cliente.clientePrioritario)
                const _MiniBadge(
                  label: 'Prioritario',
                  bg: AppColors.errorBg,
                  fg: AppColors.error,
                ),
            ],
          ),
          if (cliente.permiteCredito) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MiniBadge(
                  label: 'Crédito activo',
                  bg: AppColors.successBg,
                  fg: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.xs),
                _MiniBadge(
                  label: 'Límite: \$${_fmtMoney(cliente.limiteCredito)}',
                  bg: AppColors.neutral100,
                  fg: AppColors.textSecondary,
                ),
              ],
            ),
          ],
          if (cliente.clienteDesde != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Cliente desde: ${_fmtDate(cliente.clienteDesde!)}',
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────── RESUMEN FINANCIERO ──

class _ResumenFinancieroCard extends StatelessWidget {
  const _ResumenFinancieroCard({required this.cliente});
  final ClienteMock cliente;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Resumen financiero',
      child: Column(
        children: [
          _FilaMonto(label: 'Total comprado', valor: cliente.totalComprado),
          const SizedBox(height: AppSpacing.sm),
          _FilaMonto(
            label: 'Pagado',
            valor: cliente.totalPagado,
            valorColor: AppColors.success,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FilaMonto(
            label: 'Deuda actual',
            valor: cliente.deudaActual,
            valorColor: cliente.deudaActual > 0
                ? AppColors.error
                : AppColors.success,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FilaMonto(
            label: 'Crédito disponible',
            valor: cliente.creditoDisponible,
          ),
          const SizedBox(height: AppSpacing.sm),
          _FilaMonto(label: 'Ticket promedio', valor: cliente.ticketPromedio),
        ],
      ),
    );
  }
}

class _FilaMonto extends StatelessWidget {
  const _FilaMonto({required this.label, required this.valor, this.valorColor});

  final String label;
  final double valor;
  final Color? valorColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.small.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          '\$${_fmtMoney(valor)}',
          style: AppTypography.small.copyWith(
            color: valorColor ?? AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ───────────────────────────────────────────── ÚLTIMAS ÓRDENES ──

class _UltimasOrdenesCard extends StatelessWidget {
  const _UltimasOrdenesCard({required this.cliente});
  final ClienteMock cliente;

  @override
  Widget build(BuildContext context) {
    if (cliente.ultimasOrdenes.isEmpty) {
      return SectionCard(
        title: 'Últimas órdenes',
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Text(
              'Sin órdenes registradas',
              style: AppTypography.small.copyWith(color: AppColors.textMuted),
            ),
          ),
        ),
      );
    }

    return SectionCard(
      title: 'Últimas órdenes',
      child: Column(
        children: [
          // Header de tabla
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'ORDEN',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'TOTAL',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'TIPO',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'ESTADO',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, color: AppColors.border),
          ...cliente.ultimasOrdenes.map((o) => _FilaOrden(orden: o)),
        ],
      ),
    );
  }
}

class _FilaOrden extends StatelessWidget {
  const _FilaOrden({required this.orden});
  final OrdenResumen orden;

  @override
  Widget build(BuildContext context) {
    final tipoIsCredito = orden.tipoPago.toLowerCase().contains('crédito');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              '#${orden.numero}',
              style: AppTypography.small.copyWith(
                color: AppColors.primary500,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '\$${_fmtMoney(orden.total)}',
              style: AppTypography.small.copyWith(color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _MiniBadge(
                  label: orden.tipoPago,
                  bg: tipoIsCredito ? AppColors.infoBg : AppColors.successBg,
                  fg: tipoIsCredito ? AppColors.info : AppColors.success,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _MiniBadge(
                  label: orden.estado,
                  bg: AppColors.successBg,
                  fg: AppColors.success,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────── BADGE ──

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────── HELPERS ──

String _fmtMoney(double v) {
  // Formato con separador de miles (ej: 28450 → "28,450" o "1,185")
  final s = v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
  return s.replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
}

String _fmtDate(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}
