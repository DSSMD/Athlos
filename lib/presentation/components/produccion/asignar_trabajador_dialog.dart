import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class AsignarTrabajadorDialog extends StatefulWidget {
  final String areaActual;
  final String loteId;

  const AsignarTrabajadorDialog({
    super.key, 
    required this.areaActual, 
    required this.loteId,
  });

  @override
  State<AsignarTrabajadorDialog> createState() => _AsignarTrabajadorDialogState();
}

class _AsignarTrabajadorDialogState extends State<AsignarTrabajadorDialog> {
  String? _trabajadorSeleccionado;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.brandWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera con estilo de títulos del Success Dialog
              Text(
                'Asignar Trabajador',
                style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Lote: ${widget.loteId}',
                style: AppTypography.small.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),

              // ÁREA ACTUAL (Estilo de campo bloqueado Clean)
              Text(
                'Área actual',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                initialValue: widget.areaActual,
                readOnly: true,
                style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.textSecondary.withOpacity(0.05),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, 
                    vertical: AppSpacing.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide(color: AppColors.textSecondary.withOpacity(0.1)),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // DROPDOWN DE TRABAJADORES
              Text(
                'Trabajadores disponibles',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              DropdownButtonFormField<String>(
                value: _trabajadorSeleccionado,
                dropdownColor: AppColors.brandWhite,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                hint: Text(
                  'Seleccionar...', 
                  style: AppTypography.small.copyWith(color: AppColors.textSecondary),
                ),
                style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
                items: [
                  DropdownMenuItem(
                    value: '1', 
                    child: Text('Juan Pérez (${widget.areaActual})')
                  ),
                  DropdownMenuItem(
                    value: '2', 
                    child: Text('María López (${widget.areaActual})')
                  ),
                ],
                onChanged: (value) => setState(() => _trabajadorSeleccionado = value),
              ),
              const SizedBox(height: AppSpacing.xl2),

              // ACCIONES (Botón principal estilo ElevatedButton del Success Dialog)
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
                    disabledBackgroundColor: AppColors.border,
                  ),
                  onPressed: _trabajadorSeleccionado == null ? null : () {
                    // TODO: BACKEND Lógica de asignación
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Confirmar Asignación',
                    style: AppTypography.small.copyWith(
                      color: AppColors.brandWhite,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancelar',
                    style: AppTypography.small.copyWith(color: AppColors.textSecondary),
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