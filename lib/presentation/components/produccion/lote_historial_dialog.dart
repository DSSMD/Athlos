import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class LoteHistorialDialog extends StatelessWidget {
  final String loteId;
  final List<dynamic> historial;

  const LoteHistorialDialog({
    super.key,
    required this.loteId,
    this.historial = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.brandWhite, // Siguiendo tu estilo de Cliente Success
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabecera con Icono Estilo Clean
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Historial del Lote',
                    style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ID: $loteId',
                  style: AppTypography.small.copyWith(color: AppColors.textSecondary),
                ),
              ),
              const Divider(height: AppSpacing.xl2),

              // Contenido: Historial o Empty State
              SizedBox(
                height: 300,
                child: historial.isEmpty
                    ? _buildEmptyState()
                    : _buildTimeline(), // TODO: Backend
              ),

              const SizedBox(height: AppSpacing.xl),

              // Botón "Entendido" con el estilo de tu código
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary500,
                    foregroundColor: AppColors.brandWhite,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cerrar',
                    style: AppTypography.small.copyWith(
                      color: AppColors.brandWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Usamos el círculo de fondo suave de tu estilo success pero con icono de historial
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.history_rounded,
            color: AppColors.textSecondary,
            size: 32,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Sin movimientos',
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Este lote aún no tiene registros en el sistema.',
          textAlign: TextAlign.center,
          style: AppTypography.small.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildTimeline() {
    // Espacio reservado para el backend
    return Container();
  }
}