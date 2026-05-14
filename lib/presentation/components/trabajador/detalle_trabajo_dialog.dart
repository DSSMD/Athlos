import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. IMPORTANTE: Importamos Riverpod
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../../domain/models/trabajo_asignado_model.dart';
import '../../providers/produccion_provider.dart';

// 3. CAMBIO: De StatefulWidget a ConsumerStatefulWidget
class DetalleTrabajoDialog extends ConsumerStatefulWidget {
  final TrabajoAsignadoModel trabajo;
  final VoidCallback? onActualizado;

  const DetalleTrabajoDialog({
    super.key,
    required this.trabajo,
    this.onActualizado,
  });

  @override
  ConsumerState<DetalleTrabajoDialog> createState() =>
      _DetalleTrabajoDialogState();
}

// 4. CAMBIO: De State a ConsumerState
class _DetalleTrabajoDialogState extends ConsumerState<DetalleTrabajoDialog> {
  bool _isUpdating = false;

  Future<void> _cambiarEstado(String nuevoEstado) async {
    // 1. ¡LA LÍNEA MÁGICA! Quitamos el foco del botón para que Flutter Web no colapse
    FocusManager.instance.primaryFocus?.unfocus();

    setState(() {
      _isUpdating = true;
    });

    try {
      await ref
          .read(misTrabajosProvider.notifier)
          .cambiarEstado(widget.trabajo.idAsignacion, nuevoEstado);

      if (widget.onActualizado != null) {
        widget.onActualizado!();
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Trabajo marcado como $nuevoEstado exitosamente.'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoActual = widget.trabajo.estado.toUpperCase();

    return Dialog(
      backgroundColor: AppColors.brandWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
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
                  Text(
                    'Detalle de Tarea',
                    style: AppTypography.h3.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(
                'Lote: ${widget.trabajo.loteId}',
                style: AppTypography.small.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Información Operativa
              _buildInfoSection(
                'CANTIDAD A PRODUCIR:',
                '${widget.trabajo.cantidad} unidades',
              ),
              // En detalle_trabajo_dialog.dart busca la sección de tallas y déjala así:
              _buildInfoSection(
                'TALLAS ASIGNADAS:',
                widget.trabajo.tallas,
              ), // Ya no necesita .join

              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Divider(color: AppColors.border, thickness: 0.5),
              ),

              // Instrucciones adicionales
              Text(
                'INSTRUCCIONES:',
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  widget.trabajo.instrucciones,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl2),

              // ACCIONES CON LÓGICA DE BASE DE DATOS
              if (_isUpdating)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        // Botón Iniciar
                        onPressed: () => _cambiarEstado(
                          'en proceso',
                        ), // El servicio detectará esto y usará el ID 2
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          side: BorderSide(
                            color: estadoActual == 'PENDIENTE'
                                ? AppColors.primary500
                                : Colors.grey,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          'Iniciar trabajo',
                          style: TextStyle(
                            color: estadoActual == 'PENDIENTE'
                                ? AppColors.primary500
                                : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: estadoActual == 'EN PROCESO'
                            ? () => _cambiarEstado('terminado')
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: estadoActual == 'EN PROCESO'
                              ? AppColors.primary500
                              : Colors.grey.shade300,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                        child: Text(
                          'Terminado',
                          style: TextStyle(
                            color: estadoActual == 'EN PROCESO'
                                ? Colors.white
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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

  Widget _buildInfoSection(
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontSize: 10,
              letterSpacing: 1.1,
              color: AppColors.textSecondary,
            ),
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
