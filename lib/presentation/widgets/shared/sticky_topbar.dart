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

import 'search_input.dart';

class StickyTopbar extends StatelessWidget {
  const StickyTopbar({
    super.key,
    required this.title,
    required this.searchHint,
    required this.searchController,
    required this.onSearchChanged,
    required this.newButtonLabelDesktop,
    required this.onNewPressed,
    this.newButtonColor,
    this.newTextColor,
  });

  final String title;
  final String searchHint;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final Color? newButtonColor;
  final Color? newTextColor;

  /// Label completo para desktop (ej: "Nuevo usuario")
  final String newButtonLabelDesktop;

  final VoidCallback onNewPressed;

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
      child: Row(
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
          const SizedBox(width: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: onNewPressed,
            icon: const Icon(Icons.add, size: 18),
            label: Text(newButtonLabelDesktop),
            style: FilledButton.styleFrom(
              backgroundColor: newButtonColor,
              foregroundColor: newTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
