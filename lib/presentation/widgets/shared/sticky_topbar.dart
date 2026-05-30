// ============================================================================
// sticky_topbar.dart
// Ubicación: lib/presentation/widgets/shared/sticky_topbar.dart
// Descripción: Barra superior sticky para pantallas de listado en DESKTOP
// (Usuarios, Clientes, Órdenes, etc.). Contiene título + buscador + botón
// "nuevo".
//
// IMPORTANTE: este widget es solo desktop. El header mobile lo unifica
// `MobileScreenHeader` (con search/tabs vía su `bottom` slot) — esa es la
// convención del design system. Si necesitás un header mobile, usá
// MobileScreenHeader, NO este.
// ============================================================================

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/breakpoints.dart';
import 'search_input.dart';

class StickyTopbar extends StatelessWidget {
  const StickyTopbar({
    super.key,
    required this.title,
    required this.searchHint,
    required this.searchController,
    required this.onSearchChanged,
    this.newButtonLabelMobile,
    this.newButtonLabelDesktop,
    this.onNewPressed,
    this.newButtonColor,
    this.newTextColor,
  });

  final String title;
  final String searchHint;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final Color? newButtonColor;
  final Color? newTextColor;

  final String? newButtonLabelMobile;
  final String? newButtonLabelDesktop;

  final VoidCallback? onNewPressed;

  // Propiedad auxiliar para saber si debemos mostrar el botón
  bool _showButton(BuildContext context) =>
      onNewPressed != null &&
      (context.isMobile
          ? newButtonLabelMobile != null
          : newButtonLabelDesktop != null);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl2,
        vertical: AppSpacing.xl,
      ),
      child: context.isMobile ? _buildMobile(context) : _buildDesktop(context),
    );
  }

  Widget _buildMobile(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: AppTypography.h1)),
            // Solo renderiza el botón si las propiedades existen
            if (_showButton(context))
              ElevatedButton.icon(
                onPressed: onNewPressed,
                icon: const Icon(Icons.add, size: 18),
                label: Text(
                  newButtonLabelMobile!,
                ), // Aquí el ! es seguro por el if
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SearchInput(
          hintText: searchHint,
          controller: searchController,
          onChanged: onSearchChanged,
        ),
      ],
    );
  }

  Widget _buildDesktop(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppTypography.h1),
        const Spacer(),
        SizedBox(
          width: 320,
          child: SearchInput(
            hintText: searchHint,
            controller: searchController,
            onChanged: onSearchChanged,
          ),
        ),
        // Solo renderiza el espacio y el botón si existen
        if (_showButton(context)) ...[
          const SizedBox(width: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: onNewPressed,
            icon: const Icon(Icons.add, size: 18),
            label: Text(newButtonLabelDesktop!),
          ),
        ],
      ],
    );
  }
}
