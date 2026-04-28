// ============================================================================
// orden_materiales_card.dart
// Ubicación: lib/presentation/components/ordenes/orden_materiales_card.dart
// Descripción: Card "Materiales requeridos (calculadora)" del form Crear Orden.
// ============================================================================

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import 'orden_draft.dart';

class OrdenMaterialesCard extends StatelessWidget {
  final OrdenDraft draft;
  final ValueChanged<OrdenDraft> onChanged;
  final VoidCallback onRecalcular; // <-- Función delegada al widget padre

  const OrdenMaterialesCard({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.onRecalcular,
  });

  static const double _compactBreakpoint = 600;

  @override
  Widget build(BuildContext context) {
    final materiales = draft.materiales;

    // Buscar si hay algún material con stock insuficiente
    final materialInsuficiente = materiales.firstWhere(
      (m) => m.estado == 'insuficiente',
      orElse: () => const OrdenMaterialRequerido(
        material: '',
        requerido: 0,
        stockActual: 0,
        unidad: '',
      ),
    );

    final hayInsuficiente = materialInsuficiente.material.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < _compactBreakpoint;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(isCompact),
              const SizedBox(height: AppSpacing.lg),

              if (materiales.isEmpty)
                const _EmptyState()
              else if (isCompact)
                _listaMobile(materiales)
              else
                _tablaDesktop(materiales),

              if (hayInsuficiente) ...[
                const SizedBox(height: AppSpacing.lg),
                _bannerAlerta(materialInsuficiente),
              ],
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _header(bool isCompact) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Materiales requeridos', style: AppTypography.h3),
              Text(
                'Cálculo basado en las recetas de producción',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (isCompact)
          IconButton(
            onPressed: onRecalcular,
            icon: const Icon(Icons.refresh),
            tooltip: 'Recalcular',
            color: AppColors.primary500,
          )
        else
          OutlinedButton.icon(
            onPressed: onRecalcular,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Recalcular costos'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary500,
              side: const BorderSide(color: AppColors.primary500),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TABLA DESKTOP
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _tablaDesktop(List<OrdenMaterialRequerido> materiales) {
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(4),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
        4: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.border)),
          ),
          children: [
            _headerCell('MATERIAL'),
            _headerCell('REQUERIDO'),
            _headerCell('STOCK'),
            _headerCell('DESPUÉS'),
            _headerCell('ESTADO'),
          ],
        ),
        ...materiales.map(
          (m) => TableRow(
            children: [
              _dataCell(m.material, isBold: true),
              _dataCell('${m.requerido} ${m.unidad}'),
              _dataCell('${m.stockActual} ${m.unidad}'),
              _dataCell('${m.despues} ${m.unidad}'),
              _statusCell(m.estado),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LISTA MOBILE & COMPONENTES AUXILIARES
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _listaMobile(List<OrdenMaterialRequerido> materiales) {
    return Column(
      children: materiales.map((m) => Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(m.material, style: AppTypography.smallBold),
                _statusBadge(m.estado),
              ],
            ),
            const Divider(),
            _rowMobile('Requerido', '${m.requerido} ${m.unidad}'),
            _rowMobile('Stock actual', '${m.stockActual} ${m.unidad}'),
          ],
        ),
      )).toList(),
    );
  }

  Widget _bannerAlerta(OrdenMaterialRequerido m) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Stock insuficiente de ${m.material}. Se requieren ${m.requerido} ${m.unidad} pero solo hay ${m.stockActual}.',
              style: AppTypography.small.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String label) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
    child: Text(label, style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold)),
  );

  Widget _dataCell(String val, {bool isBold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    child: Text(val, style: isBold ? AppTypography.smallBold : AppTypography.small),
  );

  Widget _statusCell(String estado) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
    child: _statusBadge(estado),
  );

  Widget _statusBadge(String estado) {
    final isOk = estado == 'disponible';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isOk ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado.toUpperCase(),
        style: TextStyle(
          color: isOk ? Colors.green : Colors.red,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _rowMobile(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTypography.caption),
        Text(value, style: AppTypography.small),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            Icon(Icons.calculate_outlined, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Añade productos arriba y pulsa "Recalcular" para ver los materiales necesarios.',
              textAlign: TextAlign.center,
              style: AppTypography.small.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}