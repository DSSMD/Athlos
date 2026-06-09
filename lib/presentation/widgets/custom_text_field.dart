// ============================================================================
// custom_text_field.dart
// Ubicación: lib/presentation/widgets/custom_text_field.dart
// Descripción: TextField reutilizable con label superior, (opcional)/*required,
// validación visual (borde rojo + mensaje de error + ícono check/error) y
// soporte para suffix custom (ej: botón "Mostrar" en contraseñas).
//
// IMPORTANTE: el campo acepta un `errorText` externo. Cuando viene un error
// desde afuera (típicamente desde el form padre tras validación), el campo
// muestra el mensaje y el ícono de error. Si no hay error externo y el campo
// tiene contenido válido, muestra el check verde.
// ============================================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

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
    this.errorText,
    this.inputFormatters,
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

  /// Mensaje de error externo. Si está presente, anula el validator interno
  /// y se muestra inmediatamente.
  final String? errorText;

  /// Filtros de entrada para restringir caracteres (números, letras, etc.).
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  String? _internalError;
  bool _touched = false;

  void _validate(String value) {
    if (widget.validator != null) {
      final error = widget.validator!(value);
      setState(() => _internalError = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    // El error externo (del form padre) tiene prioridad sobre el interno.
    final effectiveError = widget.errorText ?? _internalError;
    final hasError = effectiveError != null;
    final hasValue = widget.controller?.text.isNotEmpty ?? false;
    // Check verde solo si: el usuario tocó el campo, no hay error de ningún tipo,
    // y hay valor escrito.
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
          inputFormatters: widget.inputFormatters,
          style: AppTypography.small,
          onChanged: (value) {
            _touched = true;
            _validate(value);
            widget.onChanged?.call(value);
          },
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: hasError ? effectiveError : null,
            suffixIcon:
                widget.suffix ??
                (showCheck
                    ? const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 20,
                      )
                    : hasError
                    ? const Icon(
                        Icons.error_outline,
                        color: AppColors.error,
                        size: 20,
                      )
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
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            ),
        ],
      ),
    );
  }
}
