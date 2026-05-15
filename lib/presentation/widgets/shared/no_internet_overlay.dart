import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class NoInternetOverlay extends StatelessWidget {
  final VoidCallback onRetry;

  const NoInternetOverlay({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background.withOpacity(0.95), // Fondo oscuro casi sólido
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                size: 80,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Conexión Perdida',
                style: AppTypography.h2.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'El sistema requiere acceso a internet para sincronizarse con la base de datos. Por favor, verifica tu conexión.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl2),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Reintentar',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary500, // Rojo Athlos
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // Radio coherente con el sistema
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}