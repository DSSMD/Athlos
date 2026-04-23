// ============================================================================
// sticky_topbar.dart
// Ubicación: lib/presentation/widgets/shared/sticky_topbar.dart
// Descripción: Barra superior sticky para pantallas de listado (Usuarios,
// Clientes, etc.). Contiene título + buscador + botón "nuevo". Se adapta a
// mobile (2 filas) y desktop (1 fila).
// ============================================================================

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import 'search_input.dart';

class StickyTopbar extends StatelessWidget {
  const StickyTopbar({
    super.key,
    required this.isMobile,
    required this.title,
    required this.searchHint,
    required this.searchController,
    required this.onSearchChanged,
    required this.newButtonLabelMobile,
    required this.newButtonLabelDesktop,
    required this.onNewPressed,
  });

  final bool isMobile;
  final String title;
  final String searchHint;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  /// Label corto para mobile (ej: "Nuevo")
  final String newButtonLabelMobile;

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
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.lg : AppSpacing.xl2,
        vertical: isMobile ? AppSpacing.lg : AppSpacing.xl,
      ),
      child: isMobile ? _buildMobile() : _buildDesktop(),
    );
  }

  Widget _buildMobile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(title, style: AppTypography.h1)),
            ElevatedButton.icon(
              onPressed: onNewPressed,
              icon: const Icon(Icons.add, size: 18),
              label: Text(newButtonLabelMobile),
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

  Widget _buildDesktop() {
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
        const SizedBox(width: AppSpacing.md),
        ElevatedButton.icon(
          onPressed: onNewPressed,
          icon: const Icon(Icons.add, size: 18),
          label: Text(newButtonLabelDesktop),
        ),
      ],
    );
  }
}
