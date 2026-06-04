// ============================================================================
// lib/presentation/widgets/notificaciones/notification_panel_launcher.dart
// ============================================================================
// Despacha el panel de notificaciones (`NotificationCenter`) con el shape
// apropiado al breakpoint actual: bottom sheet en mobile, dialog top-right
// en desktop.
//
// Por qué vive en archivo aparte:
//   - Se invoca desde 2+ lugares (bell del header mobile + item Avisos del
//     sidebar desktop, y futuras entradas). Centralizamos el "cómo se
//     presenta" acá para que cada caller no replique la lógica responsive.
//
// Decisiones de presentación:
//   - Mobile: showModalBottomSheet — patrón estándar de Material para
//     panels efímeros. Drag-to-dismiss gratis, grabber visual arriba.
//   - Desktop: showDialog alineado top-right — emula el dropdown que se
//     abre desde el bell del header, sin armar un Overlay manual.
//     barrierColor transparente para que no se dimee la pantalla.
// ============================================================================

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/breakpoints.dart';
import 'notification_center.dart';

/// Muestra el panel de notificaciones. La presentación depende del
/// breakpoint: bottom sheet en mobile, dialog top-right en desktop.
void showNotificationsPanel(BuildContext context) {
  if (context.isMobile) {
    _mostrarBottomSheet(context);
  } else {
    _mostrarDialogTopRight(context);
  }
}

// ─── PRESENTACIÓN MOBILE ─────────────────────────────────────────────────────

void _mostrarBottomSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grabber: handle horizontal que sugiere "arrastrable para cerrar".
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.neutral200,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
              const NotificationCenter(),
            ],
          ),
        ),
      );
    },
  );
}

// ─── PRESENTACIÓN DESKTOP ────────────────────────────────────────────────────

void _mostrarDialogTopRight(BuildContext context) {
  showDialog<void>(
    context: context,
    // Barrier transparente: el panel se siente como un dropdown del bell, no
    // como un modal que pause toda la pantalla. Tap fuera sigue cerrando.
    barrierColor: Colors.transparent,
    builder: (_) {
      return Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.xl3,
            right: AppSpacing.lg,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            // Material transparent para que los inkwells / TextButtons dentro
            // de NotificationCenter tengan ancestor Material disponible.
            child: const Material(
              type: MaterialType.transparency,
              child: NotificationCenter(),
            ),
          ),
        ),
      );
    },
  );
}
