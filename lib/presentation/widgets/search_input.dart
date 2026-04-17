// ============================================================================
// search_input.dart
// Ubicación sugerida: lib/presentation/widgets/search_input.dart
// Descripción: Input de búsqueda con ícono de lupa. Usa el InputDecorationTheme
// global pero fuerza prefix-icon + padding compacto.
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

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
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: AppTypography.small,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(
          Icons.search,
          size: 20,
          color: AppColors.textMuted,
        ),
        prefixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }
}