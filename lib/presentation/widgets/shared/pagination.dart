// ============================================================================
// pagination.dart
// Ubicación: lib/presentation/widgets/shared/pagination.dart
// Descripción: Dos widgets de paginación reutilizables:
//   - DesktopPagination: "Mostrando X-Y de Z" + botones numéricos.
//   - LoadMoreButton: botón "Cargar más..." para infinite scroll en mobile.
// ============================================================================

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Paginación para vistas desktop: etiqueta de rango + botones numéricos.
/// Se oculta automáticamente si totalItems == 0 o totalPages <= 1.
class DesktopPagination extends StatelessWidget {
  const DesktopPagination({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.totalItems,
    required this.itemsPerPage,
    required this.onPageChanged,
    this.recordsLabel = 'registros',
  });

  final int currentPage;
  final int totalPages;
  final int totalItems;
  final int itemsPerPage;
  final ValueChanged<int> onPageChanged;

  /// Permite personalizar el sustantivo: "registros", "clientes", "usuarios"...
  final String recordsLabel;

  @override
  Widget build(BuildContext context) {
    if (totalItems == 0 || totalPages <= 1) return const SizedBox.shrink();

    final startItem = ((currentPage - 1) * itemsPerPage) + 1;
    final endItem = (currentPage * itemsPerPage).clamp(0, totalItems);

    return Row(
      children: [
        Text(
          'Mostrando $startItem-$endItem de $totalItems $recordsLabel',
          style: AppTypography.small.copyWith(color: AppColors.textMuted),
        ),
        const Spacer(),
        for (int i = 1; i <= totalPages; i++)
          _pageBtn(
            i.toString(),
            selected: currentPage == i,
            onTap: () => onPageChanged(i),
          ),
      ],
    );
  }

  Widget _pageBtn(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: selected ? null : onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary500 : AppColors.neutral100,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              label,
              style: AppTypography.small.copyWith(
                color: selected ? AppColors.brandWhite : AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Botón "Cargar más..." para vistas mobile con scroll infinito.
/// Se oculta automáticamente cuando no hay más páginas por cargar.
class LoadMoreButton extends StatelessWidget {
  const LoadMoreButton({
    super.key,
    required this.hasMore,
    required this.onPressed,
    this.label = 'Cargar más...',
  });

  final bool hasMore;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (!hasMore) return const SizedBox.shrink();

    return Center(
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          label,
          style: AppTypography.small.copyWith(
            color: AppColors.primary500,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
