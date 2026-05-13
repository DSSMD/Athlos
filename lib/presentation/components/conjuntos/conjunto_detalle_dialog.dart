// lib/presentation/pages/conjuntos/widgets/conjunto_detalle_dialog.dart

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import  '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../../../domain/models/conjunto_model.dart';

class ConjuntoDetalleDialog extends StatelessWidget {
  final ConjuntoModel conjunto;

  const ConjuntoDetalleDialog({super.key, required this.conjunto});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.brandWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera con Badge de Estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Detalle del Conjunto', style: AppTypography.h3),
                        Text('ID: ${conjunto.id}', 
                          style: AppTypography.small.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  _StatusChip(activo: conjunto.activo),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Información Principal
              _buildInfoSection('NOMBRE', conjunto.nombre),
              _buildInfoSection('DESCRIPCIÓN', conjunto.descripcion),
              
              Row(
                children: [
                  Expanded(child: _buildInfoSection('PRECIO TOTAL', '${conjunto.precio.toStringAsFixed(2)} Bs.', isHighlight: true)),
                  Expanded(child: _buildInfoSection('CREADO EL', '${conjunto.fechaCreacion.day}/${conjunto.fechaCreacion.month}/${conjunto.fechaCreacion.year}')),
                ],
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Divider(color: AppColors.border),
              ),

              // Lista de Plantillas (La Receta)
              Text(
                'PLANTILLAS INCLUIDAS (${conjunto.plantillas.length})',
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              
              Flexible(
                child: conjunto.plantillas.isEmpty 
                  ? _buildEmptyPlantillas()
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: conjunto.plantillas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        final item = conjunto.plantillas[index];
                        return _PlantillaDetailCard(
                          nombre: item.nombrePlantilla,
                          cantidad: item.cantidad,
                          precioUnit: item.precioUnitario,
                          subtotal: item.subtotal,
                        );
                      },
                    ),
              ),

              const SizedBox(height: AppSpacing.xl2),

              // Botón de Cierre
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary500,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cerrar', style: AppTypography.small.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
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
          Text(label, style: AppTypography.caption.copyWith(fontSize: 10, letterSpacing: 1.1, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.body.copyWith(
            fontWeight: FontWeight.bold,
            color: isHighlight ? AppColors.primary500 : AppColors.textPrimary,
          )),
        ],
      ),
    );
  }

  Widget _buildEmptyPlantillas() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Center(
        child: Text('Este conjunto no tiene plantillas asignadas.', 
          textAlign: TextAlign.center,
          style: AppTypography.small.copyWith(color: AppColors.textSecondary)),
      ),
    );
  }
}

// Card individual para cada plantilla dentro del conjunto
class _PlantillaDetailCard extends StatelessWidget {
  final String nombre;
  final int cantidad;
  final double precioUnit;
  final double subtotal;

  const _PlantillaDetailCard({
    required this.nombre, 
    required this.cantidad, 
    required this.precioUnit, 
    required this.subtotal
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.brandWhite,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.primary500.withOpacity(0.1), shape: BoxShape.circle),
            child: Text('$cantidad', style: TextStyle(color: AppColors.primary500, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nombre, style: AppTypography.small.copyWith(fontWeight: FontWeight.bold)),
                Text('${precioUnit.toStringAsFixed(2)} Bs. c/u', style: AppTypography.caption),
              ],
            ),
          ),
          Text('${subtotal.toStringAsFixed(2)} Bs.', 
            style: AppTypography.small.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool activo;
  const _StatusChip({required this.activo});

  @override
  Widget build(BuildContext context) {
    final color = activo ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(
        activo ? 'ACTIVO' : 'INACTIVO',
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }
}