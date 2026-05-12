// ============================================================================
// sticky_topbar.dart
// Ubicación: lib/presentation/widgets/shared/sticky_topbar.dart
// Descripción: Barra superior sticky para pantallas de listado (Usuarios,
// Clientes, etc.). Contiene título + buscador + botón "nuevo".
// - Mobile: bloque oscuro (sidebarDark) — título y SearchInput agrupados
//   visualmente dentro del mismo header oscuro. Consistente con
//   MobileScreenHeader que usa Inventario y Mi Perfil.
// - Desktop: bloque blanco con border bottom (look anterior, sin cambios).
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
      decoration: BoxDecoration(
        color: isMobile ? AppColors.sidebarDark : AppColors.background,
        border: isMobile
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      // En mobile damos un poco más de aire abajo (xl en vez de lg) para que
      // el SearchInput no quede pegado al borde del bloque oscuro.
      padding: EdgeInsets.fromLTRB(
        isMobile ? AppSpacing.lg : AppSpacing.xl2,
        isMobile ? AppSpacing.lg : AppSpacing.xl,
        isMobile ? AppSpacing.lg : AppSpacing.xl2,
        isMobile ? AppSpacing.xl : AppSpacing.xl,
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
            Expanded(
              child: Text(
                title,
                style: AppTypography.h1.copyWith(
                  color: AppColors.brandWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: onNewPressed,
              icon: const Icon(Icons.add, size: 18),
              label: Text(newButtonLabelMobile),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
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
