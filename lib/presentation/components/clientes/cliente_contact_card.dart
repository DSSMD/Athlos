// ============================================================================
// cliente_contact_card.dart
// Ubicación: lib/presentation/components/clientes/cliente_contact_card.dart
// Descripción: Card "Información de contacto" — teléfono, teléfono secundario,
// email, dirección. NOTA: el botón WhatsApp se movió al tab "Resumen".
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import '../../theme/app_colors.dart'; // Asegúrate de tener este import
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/custom_text_field.dart';
import '_section_card.dart';

class ClienteContactCard extends StatelessWidget {
  const ClienteContactCard({
    super.key,
    this.telefonoController,
    this.telefonoSecController,
    required this.emailController,
    required this.direccionController,
    required this.onTelefonoCompletoChanged,
    required this.onTelefonoSecCompletoChanged,
    this.initialTelefono,
    this.initialTelefonoSec,
    this.showBadgeActualizado = false,
    this.errors = const {},
  });

  final TextEditingController? telefonoController;
  final TextEditingController? telefonoSecController;
  final TextEditingController emailController;
  final TextEditingController direccionController;

  // Callbacks para enviar el número con el código de país al Drawer
  final ValueChanged<String> onTelefonoCompletoChanged;
  final ValueChanged<String> onTelefonoSecCompletoChanged;

  final String? initialTelefono;
  final String? initialTelefonoSec;

  final bool showBadgeActualizado;
  final Map<String, String?> errors;

  @override
  Widget build(BuildContext context) {
    // Estilo de borde para que el IntlPhoneField se vea igual que tu CustomTextField
    final defaultBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(8), // Ajusta según tu AppRadius
      borderSide: const BorderSide(color: AppColors.border),
    );

    final pickerStyle = PickerDialogStyle(
      width: 400, // <--- ESTO EVITA QUE CUBRA TODA LA PANTALLA
      backgroundColor: AppColors.background,
      searchFieldInputDecoration: InputDecoration(
        labelText: 'Buscar país',
        border: defaultBorder,
      ),
    );

    return SectionCard(
      title: 'Información de contacto',
      showBadgeActualizado: showBadgeActualizado,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila 1: Teléfono + Teléfono secundario
          _Row2(
            left: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    text: 'Teléfono / WhatsApp ',
                    style: AppTypography.small.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    children: const [
                      TextSpan(
                        text: '*',
                        style: TextStyle(color: AppColors.error),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                IntlPhoneField(
                  initialValue: initialTelefono,
                  pickerDialogStyle: pickerStyle,
                  initialCountryCode: 'BO', // Bolivia
                  // ignore: deprecated_member_use
                  searchText: 'Buscar país',
                  invalidNumberMessage: 'Número inválido para este país',
                  decoration: InputDecoration(
                    hintText: 'Ej. 77712345',
                    errorText: errors['telefono'],
                    filled: true,
                    fillColor: AppColors.brandWhite,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 14,
                    ),
                    border: defaultBorder,
                    enabledBorder: defaultBorder,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.borderFocus,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (PhoneNumber phone) {
                    onTelefonoCompletoChanged(phone.completeNumber);
                  },
                ),
              ],
            ),
            right: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Teléfono secundario',
                  style: AppTypography.small.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                IntlPhoneField(
                  initialCountryCode: 'BO',
                  initialValue: initialTelefonoSec,
                  pickerDialogStyle: pickerStyle,
                  // ignore: deprecated_member_use
                  searchText: 'Buscar país',
                  invalidNumberMessage: 'Número inválido',
                  decoration: InputDecoration(
                    hintText: 'Opcional',
                    errorText: errors['telefono2'],
                    filled: true,
                    fillColor: AppColors.brandWhite,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 14,
                    ),
                    border: defaultBorder,
                    enabledBorder: defaultBorder,
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                        color: AppColors.borderFocus,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onChanged: (PhoneNumber phone) {
                    onTelefonoSecCompletoChanged(phone.completeNumber);
                  },
                ),
              ],
            ),
          ),
          // const SizedBox(height: AppSpacing.lg), <-- Ya no es necesario porque el IntlPhoneField ocupa un poco más de espacio hacia abajo por el helper text

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
