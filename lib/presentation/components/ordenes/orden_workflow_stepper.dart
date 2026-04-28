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
  /// idEstado del modelo: 1=Pendiente, 2=En Producción, 3=Finalizada, 4=Entregada.
  final int idEstado;

  const OrdenWorkflowStepper({super.key, required this.idEstado});

  @override
  Widget build(BuildContext context) {
    final currentStep = idEstado;

    const steps = [
      'Pendiente',
      'En Producción',
      'Finalizada',
      'Entregada',
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // En pantallas estrechas (< 600), apilamos vertical
        final isNarrow = constraints.maxWidth < 600;

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
              isNarrow
                  ? _buildVertical(steps, currentStep)
                  : _buildHorizontal(steps, currentStep),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHorizontal(List<String> steps, int currentStep) {
    return Row(
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
                isVertical: false,
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
    );
  }

  Widget _buildVertical(List<String> steps, int currentStep) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(steps.length, (i) {
        final stepNumber = i + 1;
        final isLast = i == steps.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columna del círculo + línea conectora vertical
              Column(
                children: [
                  _StepCircle(
                    number: stepNumber,
                    label: '', // sin label aquí, va al lado
                    state: _stateFor(stepNumber, currentStep),
                    isVertical: true,
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        color: stepNumber < currentStep
                            ? AppColors.success
                            : AppColors.border,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              // Label al lado del círculo
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: AppSpacing.sm,
                    bottom: isLast ? 0 : AppSpacing.lg,
                  ),
                  child: Text(
                    steps[i],
                    style: AppTypography.small.copyWith(
                      color:
                          _stateFor(stepNumber, currentStep) ==
                              _StepState.pending
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                      fontWeight:
                          _stateFor(stepNumber, currentStep) ==
                              _StepState.active
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
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
  final bool isVertical;

  const _StepCircle({
    required this.number,
    required this.label,
    required this.state,
    this.isVertical = false,
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

    final circle = Container(
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
    );

    if (isVertical) {
      return circle;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        circle,
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
