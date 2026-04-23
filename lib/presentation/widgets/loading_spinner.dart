// ============================================================================
// loading_spinner.dart
// Ubicación sugerida: lib/presentation/widgets/loading_spinner.dart
// Descripción: Spinner de carga reutilizable. Widget atómico, estilado con
// el color primary de Athlos. Tiene 3 tamaños preset (sm/md/lg) para
// diferentes contextos: dentro de botones, tarjetas, o pantallas completas.
//
// Uso:
//   LoadingSpinner()                    → tamaño default (md)
//   LoadingSpinner(size: LoadingSize.sm) → dentro de botón pequeño
//   LoadingSpinner.fullScreen()          → pantalla completa con overlay
// ============================================================================

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

enum LoadingSize { sm, md, lg }

class LoadingSpinner extends StatelessWidget {
  const LoadingSpinner({
    super.key,
    this.size = LoadingSize.md,
    this.color,
    this.strokeWidth,
  }) : message = null;

  /// Spinner centrado sobre overlay oscuro. Útil para cargas a pantalla completa.
  const LoadingSpinner.fullScreen({super.key, this.message})
    : size = LoadingSize.lg,
      color = null,
      strokeWidth = null;

  final LoadingSize size;
  final Color? color;
  final double? strokeWidth;
  final String? message;

  double get _dimension {
    switch (size) {
      case LoadingSize.sm:
        return 16;
      case LoadingSize.md:
        return 24;
      case LoadingSize.lg:
        return 40;
    }
  }

  double get _stroke {
    if (strokeWidth != null) return strokeWidth!;
    switch (size) {
      case LoadingSize.sm:
        return 2;
      case LoadingSize.md:
        return 2.5;
      case LoadingSize.lg:
        return 3.5;
    }
  }

  @override
  Widget build(BuildContext context) {
    final spinner = SizedBox(
      width: _dimension,
      height: _dimension,
      child: CircularProgressIndicator(
        strokeWidth: _stroke,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? AppColors.primary500,
        ),
      ),
    );

    // Modo pantalla completa
    if (message != null) {
      return Container(
        color: Colors.black.withValues(alpha: 0.5),
        alignment: Alignment.center,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              spinner,
              const SizedBox(height: 12),
              Text(
                message!,
                style: AppTypography.small,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return spinner;
  }
}
