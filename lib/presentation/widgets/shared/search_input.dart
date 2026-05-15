// ============================================================================
// search_input.dart
// Ubicación: lib/presentation/widgets/shared/search_input.dart
// Descripción: Input de búsqueda con ícono de lupa. Define su PROPIO
// decoration (border, fill, hint, icon) en vez de heredar del
// InputDecorationTheme global — esto mantiene los TextField del resto de
// la app intactos y solo el buscador queda con su look propio:
//   - Border neutral400 (más oscuro que neutral200 del tema, para que se
//     vea sobre fondos casi blancos).
//   - Fill background (#FFFFFF) — sutilmente distinto del surface (#FAFAFA)
//     de las páginas, para que el campo destaque.
//   - Ícono de lupa con textSecondary (más contraste que el textMuted
//     original).
//   - Focus border con primary500 (rojo marca) para feedback claro.
// ============================================================================

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class SearchInput extends StatelessWidget {
  const SearchInput({
    super.key,
    this.hintText = 'Buscar...',
    this.onChanged,
    this.controller,
  });

  final String hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.md);

    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTypography.small.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: AppTypography.small.copyWith(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.background,
        prefixIcon: const Icon(
          Icons.search,
          size: 20,
          color: AppColors.textSecondary,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.neutral400),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: AppColors.neutral400),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(
            color: AppColors.borderFocus,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
