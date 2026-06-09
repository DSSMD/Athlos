// ============================================================================
// orden_prioridad_card.dart
// Ubicación: lib/presentation/components/ordenes/orden_prioridad_card.dart
// Descripción: Card "Prioridad" de la columna lateral (SCRUM-75).
// Radio buttons: Normal / Alta / Urgente.
// ============================================================================

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import 'orden_draft.dart';

class OrdenPrioridadCard extends StatelessWidget {
  final OrdenDraft draft;
  final ValueChanged<OrdenDraft> onChanged;

  const OrdenPrioridadCard({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  void _set(OrdenPrioridad p) {
    onChanged(draft.copyWith(prioridad: p));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Prioridad', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.lg),
          _opcion(label: 'Normal', value: OrdenPrioridad.normal),
          const SizedBox(height: AppSpacing.sm),
          _opcion(label: 'Alta', value: OrdenPrioridad.alta),
          const SizedBox(height: AppSpacing.sm),
          _opcion(label: 'Urgente', value: OrdenPrioridad.urgente),
        ],
      ),
    );
  }

  Widget _opcion({required String label, required OrdenPrioridad value}) {
    final selected = draft.prioridad == value;
    return InkWell(
      onTap: () => _set(value),
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            _radio(selected),
            const SizedBox(width: AppSpacing.md),
            Text(label, style: AppTypography.body),
          ],
        ),
      ),
    );
  }

  Widget _radio(bool selected) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary500 : AppColors.border,
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary500,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}
