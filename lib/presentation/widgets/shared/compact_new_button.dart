// ============================================================================
// compact_new_button.dart
// Ubicación: lib/presentation/widgets/shared/compact_new_button.dart
// Descripción: Botón compacto "+ Nuevo" para usar en el slot trailing del
// MobileScreenHeader oscuro. Look definido: fondo primary500, texto blanco,
// ícono `+` y label corto. Centraliza el patrón duplicado que tenían
// Clientes, Usuarios y Órdenes (cada uno con su _CompactNewButton privado).
// ============================================================================

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class CompactNewButton extends StatelessWidget {
  const CompactNewButton({
    super.key,
    required this.onPressed,
    this.label = 'Nuevo',
  });

  final VoidCallback onPressed;

  /// Texto VISIBLE al lado del ícono "+". Default `'Nuevo'`. Ej.: pasar
  /// `'Nueva'` cuando el sustantivo es femenino (Órdenes → "Nueva orden").
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary500,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add, size: 16, color: AppColors.brandWhite),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: AppTypography.small.copyWith(
                  color: AppColors.brandWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
