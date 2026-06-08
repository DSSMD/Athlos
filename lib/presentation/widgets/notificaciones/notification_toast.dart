// ============================================================================
// lib/presentation/widgets/notificaciones/notification_toast.dart
// ============================================================================
// Widget DUMB para mostrar una notificación como toast efímero.
//
// Sólo renderiza. NO maneja:
//   - auto-dismiss
//   - posicionamiento (top-right, bottom-center, etc.)
//   - cola de varios toasts simultáneos
// Todo eso lo decide el caller en Bloque 3 (ej. Overlay + Timer + Stack).
//
// Tinte por prioridad:
//   - informativa → fondo infoBg + borde/icono info + Icons.info_outline
//   - advertencia → fondo warningBg + borde/icono warning + Icons.warning_amber_outlined
//   - critica     → fondo errorBg + borde/icono error + Icons.error_outline
//   - null        → tonos neutros (caso defensivo, no debería pasar en BD)
//
// Ancho:
//   - desktop: máx 320 px (constraint).
//   - mobile: full-width con padding lateral del caller — este widget
//     ya respeta el ancho disponible, así que no necesita branching propio.
// ============================================================================

import 'package:flutter/material.dart';

import '../../../domain/models/notificacion_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/breakpoints.dart';

class NotificationToast extends StatelessWidget {
  const NotificationToast({
    super.key,
    required this.notificacion,
    this.onClose,
  });

  final NotificacionModel notificacion;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final estilo = _estiloPorPrioridad(notificacion.prioridad);
    final isMobile = context.isMobile;

    final card = Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: estilo.background,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: estilo.foreground, width: 1),
        boxShadow: AppShadows.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(estilo.icono, color: estilo.foreground, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notificacion.titulo ?? 'Sin título',
                  style: AppTypography.small.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (notificacion.mensaje != null &&
                    notificacion.mensaje!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    notificacion.mensaje!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Botón X con tap target cómodo, sin foco visual permanente.
          InkWell(
            onTap: onClose,
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.close,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );

    // En desktop el toast se limita a 320 px; en mobile se expande al
    // ancho disponible que le dé el caller (overlay / padding).
    if (isMobile) {
      return card;
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: card,
    );
  }
}

// ─── HELPERS PRIVADOS ────────────────────────────────────────────────────────

class _EstiloPrioridad {
  const _EstiloPrioridad({
    required this.background,
    required this.foreground,
    required this.icono,
  });
  final Color background;
  final Color foreground;
  final IconData icono;
}

/// Mapeo prioridad → tonos + icono. Mantenemos `null` como caso defensivo
/// con tonos neutros para evitar crashes si la BD trae una prioridad fuera
/// del CHECK constraint.
_EstiloPrioridad _estiloPorPrioridad(PrioridadNotificacion? prioridad) {
  switch (prioridad) {
    case PrioridadNotificacion.informativa:
      return const _EstiloPrioridad(
        background: AppColors.infoBg,
        foreground: AppColors.info,
        icono: Icons.info_outline,
      );
    case PrioridadNotificacion.advertencia:
      return const _EstiloPrioridad(
        background: AppColors.warningBg,
        foreground: AppColors.warning,
        icono: Icons.warning_amber_outlined,
      );
    case PrioridadNotificacion.critica:
      return const _EstiloPrioridad(
        background: AppColors.errorBg,
        foreground: AppColors.error,
        icono: Icons.error_outline,
      );
    case null:
      return const _EstiloPrioridad(
        background: AppColors.neutral100,
        foreground: AppColors.neutral500,
        icono: Icons.notifications_outlined,
      );
  }
}
