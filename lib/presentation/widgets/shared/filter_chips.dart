// ============================================================================
// filter_chips.dart
// Ubicación: lib/presentation/widgets/shared/filter_chips.dart
// Descripción: Chips de filtro con contadores (ej: "Todos (89)", "Activos (34)").
// Selección mutuamente excluyente. Reutilizable en cualquier listado.
// ============================================================================

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class FilterChips extends StatelessWidget {
  const FilterChips({
    super.key,
    required this.labels,
    required this.counts,
    required this.selected,
    required this.onChanged,
  });

  final List<String> labels;
  final List<int> counts;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    assert(
      labels.length == counts.length,
      'labels y counts deben tener la misma longitud',
    );
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: List.generate(labels.length, (i) {
        final isSelected = selected == i;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onChanged(i),
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary500 : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: isSelected ? AppColors.primary500 : AppColors.border,
                ),
              ),
              child: Text(
                '${labels[i]} (${counts[i]})',
                style: AppTypography.small.copyWith(
                  color: isSelected
                      ? AppColors.brandWhite
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
