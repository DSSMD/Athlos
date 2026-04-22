// lib/presentation/widgets/users/custom_text_field.dart
// ============================================================================
// Descripción: TextField personalizado con validación integrada, estilos adaptados al diseño de Athlos, y soporte para estados de error y éxito.
// Permite mostrar un ícono de check o error según el estado de validación, y tiene opciones para marcar el campo como requerido u opcional.
// Cumple con el punto del checklist JIRA "Input de texto con validación y estados visuales".
// ============================================================================

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    this.isRequired = false,
    this.isOptional = false,
    this.controller,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.suffix,
    this.enabled = true,
  });

  final String label;
  final String? hint;
  final bool isRequired;
  final bool isOptional;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  final bool enabled;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  String? _errorText;
  bool _touched = false;

  void _validate(String value) {
    if (widget.validator != null) {
      final error = widget.validator!(value);
      setState(() => _errorText = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = _touched && _errorText != null;
    final hasValue = widget.controller?.text.isNotEmpty ?? false;
    final showCheck = _touched && !hasError && hasValue;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          enabled: widget.enabled,
          style: AppTypography.small,
          onChanged: (value) {
            _touched = true;
            _validate(value);
            widget.onChanged?.call(value);
          },
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: hasError ? _errorText : null,
            suffixIcon: widget.suffix ??
                (showCheck
                    ? const Icon(Icons.check_circle,
                        color: AppColors.success, size: 20)
                    : hasError
                        ? const Icon(Icons.error_outline,
                            color: AppColors.error, size: 20)
                        : null),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel() {
    return RichText(
      text: TextSpan(
        style: AppTypography.small.copyWith(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        children: [
          TextSpan(text: widget.label),
          if (widget.isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AppColors.error),
            ),
          if (widget.isOptional)
            TextSpan(
              text: ' (opcional)',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}