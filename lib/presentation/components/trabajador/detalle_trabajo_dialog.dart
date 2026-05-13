import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../../domain/models/trabajo_asignado_model.dart';

class DetalleTrabajoDialog extends StatelessWidget {
  final TrabajoAsignadoModel trabajo;

  const DetalleTrabajoDialog({super.key, required this.trabajo});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.brandWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera estilizada
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Detalle de Tarea', style: AppTypography.h3.copyWith(color: AppColors.textPrimary)),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text('Lote: ${trabajo.loteId}', style: AppTypography.small.copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.xl),

              // Información Operativa (Punto 2 de tu plantilla)
              _buildInfoSection('¿QUÉ DEBE HACER?', trabajo.actividad, isHighlight: true),
              _buildInfoSection('CANTIDAD A PRODUCIR:', '${trabajo.cantidad} unidades'),
              _buildInfoSection('TALLAS ASIGNADAS:', trabajo.tallas.join(', ')),
              
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Divider(color: AppColors.border, thickness: 0.5),
              ),

              // Instrucciones adicionales
              Text(
                'INSTRUCCIONES:',
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  trabajo.instrucciones,
                  style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                ),
              ),

              const SizedBox(height: AppSpacing.xl2),

              // ACCIONES (Punto 3 de tu plantilla)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: trabajo.estado == 'PENDIENTE' ? () {
                        // TODO: BACKEND - Update estado a 'EN PROCESO'
                        Navigator.pop(context);
                      } : null, // Se deshabilita si ya inició
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        side: const BorderSide(color: AppColors.primary500),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                      child: Text('Iniciar trabajo', style: TextStyle(color: AppColors.primary500, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: trabajo.estado == 'EN PROCESO' ? () {
                        // TODO: BACKEND - Update estado a 'TERMINADO'
                        Navigator.pop(context);
                      } : null, // Solo se habilita si ya inició
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary500,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                      ),
                      child: const Text('Terminado', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(fontSize: 10, letterSpacing: 1.1, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.body.copyWith(
              fontWeight: FontWeight.bold,
              color: isHighlight ? AppColors.primary500 : AppColors.textPrimary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}