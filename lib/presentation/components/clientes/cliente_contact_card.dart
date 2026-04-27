// ============================================================================
// cliente_contact_card.dart
// Ubicación: lib/presentation/components/clientes/cliente_contact_card.dart
// Descripción: Card "Información de contacto" — teléfono, teléfono secundario,
// email, dirección. NOTA: el botón WhatsApp se movió al tab "Resumen" porque
// no tiene sentido contactar a un cliente mientras se lo está creando/editando.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/custom_text_field.dart';
import '_section_card.dart';

class ClienteContactCard extends StatelessWidget {
  const ClienteContactCard({
    super.key,
    required this.telefonoController,
    required this.telefonoSecController,
    required this.emailController,
    required this.direccionController,
    this.showBadgeActualizado = false,
    this.errors = const {},
  });

  final TextEditingController telefonoController;
  final TextEditingController telefonoSecController;
  final TextEditingController emailController;
  final TextEditingController direccionController;
  final bool showBadgeActualizado;
  final Map<String, String?> errors;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Información de contacto',
      showBadgeActualizado: showBadgeActualizado,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila 1: Teléfono + Teléfono secundario
          _Row2(
            left: CustomTextField(
              controller: telefonoController,
              label: 'Teléfono / WhatsApp',
              isRequired: true,
              errorText: errors['telefono'],
              keyboardType: TextInputType.phone,
              inputFormatters: [
                // Solo números, espacios, +, -, paréntesis
                FilteringTextInputFormatter.allow(RegExp(r'[0-9\s+\-()]')),
              ],
            ),
            right: CustomTextField(
              controller: telefonoSecController,
              label: 'Teléfono secundario',
              isOptional: true,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9\s+\-()]')),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Fila 2: Email + Dirección
          _Row2(
            left: CustomTextField(
              controller: emailController,
              label: 'Email',
              isOptional: true,
              errorText: errors['email'],
              keyboardType: TextInputType.emailAddress,
            ),
            right: CustomTextField(
              controller: direccionController,
              label: 'Dirección',
              isOptional: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _Row2 extends StatelessWidget {
  const _Row2({required this.left, required this.right});
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          left,
          const SizedBox(height: AppSpacing.lg),
          right,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: AppSpacing.lg),
        Expanded(child: right),
      ],
    );
  }
}
