// lib/presentation/pages/conjuntos/widgets/conjunto_row.dart
import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import  '../../../../theme/app_typography.dart';
import '../../../../../domain/models/conjunto_model.dart';

class ConjuntoRow extends StatelessWidget {
  final ConjuntoModel conjunto;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ConjuntoRow({
    super.key,
    required this.conjunto,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg, 
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // Nombre y descripción
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  conjunto.nombre,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  conjunto.descripcion,
                  style: AppTypography.small.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Precio
          Expanded(
            flex: 2,
            child: Text(
              '${conjunto.precioTotal.toStringAsFixed(2)} Bs.',
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
            ),
          ),

          // Cantidad de plantillas (Badge sutil)
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Icon(Icons.layers_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${conjunto.plantillas.length} pzas',
                  style: AppTypography.small.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          // Estado (Badge de color)
          Expanded(
            flex: 2,
            child: _StatusBadge(activo: conjunto.activo),
          ),

          // Acciones (PopupMenuButton estilizado)
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerRight,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                tooltip: 'Acciones',
                onSelected: (value) {
                  if (value == 'ver') onView();
                  if (value == 'editar') onEdit();
                  if (value == 'estado') onDelete(); // Reutilizamos onDelete como toggle de estado (Soft Delete)
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'ver',
                    child: Row(
                      children: [
                        Icon(Icons.visibility, size: 18),
                        SizedBox(width: 8),
                        Text('Ver Detalles'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'editar',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 18),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'estado',
                    child: Row(
                      children: [
                        Icon(
                          conjunto.activo ? Icons.block : Icons.check_circle_outline,
                          size: 18,
                          color: conjunto.activo ? AppColors.error : AppColors.success,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          conjunto.activo ? 'Desactivar' : 'Activar',
                          style: TextStyle(
                            color: conjunto.activo ? AppColors.error : AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Badge de estado interno para el widget
class _StatusBadge extends StatelessWidget {
  final bool activo;
  const _StatusBadge({required this.activo});

  @override
  Widget build(BuildContext context) {
    final color = activo ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            activo ? 'Activo' : 'Inactivo',
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}