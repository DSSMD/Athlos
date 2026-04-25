// ============================================================================
// orden_workflow_stepper.dart
// Ubicación: lib/presentation/components/ordenes/orden_workflow_stepper.dart
// Descripción: Stepper visual de 5 pasos para mostrar el estado del pedido
// (Registrada → Confirmada → En producción → Control calidad → Entregada).
// ============================================================================

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class OrdenWorkflowStepper extends StatelessWidget {
  /// idEstado del modelo: 1=pendiente, 2=producción, 3=entregado, 4=cancelado.
  /// Este mapeo a pasos 1..5 es aproximado — cuando backend expanda los
  /// estados (Confirmada, Control calidad), se ajusta acá.
  final int idEstado;

  const OrdenWorkflowStepper({super.key, required this.idEstado});

  @override
  Widget build(BuildContext context) {
    // Mapeo simple: 1 pendiente → paso 1
    //               2 producción → paso 3
    //               3 entregado → paso 5
    //               4 cancelado → paso 1 (con marca de cancelado)
    final currentStep = _mapIdEstadoToStep(idEstado);

    const steps = [
      'Registrada',
      'Confirmada',
      'En producción',
      'Control calidad',
      'Entregada',
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estado del pedido', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: List.generate(steps.length, (i) {
              final stepNumber = i + 1;
              final isLast = i == steps.length - 1;
              return Expanded(
                flex: isLast ? 0 : 1,
                child: Row(
                  children: [
                    _StepCircle(
                      number: stepNumber,
                      label: steps[i],
                      state: _stateFor(stepNumber, currentStep),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          color: stepNumber < currentStep
                              ? AppColors.success
                              : AppColors.border,
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  int _mapIdEstadoToStep(int idEstado) {
    switch (idEstado) {
      case 1:
        return 1;
      case 2:
        return 3;
      case 3:
        return 5;
      case 4:
        return 1;
      default:
        return 1;
    }
  }

  _StepState _stateFor(int stepNumber, int currentStep) {
    if (stepNumber < currentStep) return _StepState.done;
    if (stepNumber == currentStep) return _StepState.active;
    return _StepState.pending;
  }
}

enum _StepState { done, active, pending }

class _StepCircle extends StatelessWidget {
  final int number;
  final String label;
  final _StepState state;

  const _StepCircle({
    required this.number,
    required this.label,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    final (bgColor, textColor, labelColor) = switch (state) {
      _StepState.done => (
        AppColors.success,
        AppColors.brandWhite,
        AppColors.success,
      ),
      _StepState.active => (
        AppColors.primary500,
        AppColors.brandWhite,
        AppColors.primary500,
      ),
      _StepState.pending => (
        AppColors.neutral200,
        AppColors.textMuted,
        AppColors.textMuted,
      ),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: state == _StepState.done
              ? const Icon(Icons.check, color: AppColors.brandWhite, size: 20)
              : Text(
                  '$number',
                  style: AppTypography.small.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: labelColor,
            fontWeight: state == _StepState.active
                ? FontWeight.w600
                : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}