// ============================================================================
// lib/presentation/widgets/notificaciones/notification_bell.dart
// ============================================================================
// Widget SMART — campana con badge de no-leídas.
//
// Watchea unreadNotificacionesCountProvider. No abre nada por sí solo: el
// caller cablea el onTap en Bloque 3 (mostrar popup, navegar, etc.).
//
// Estados visuales:
//   - count == 0 → icono outlined, sin badge.
//   - count >= 1 → icono lleno, badge rojo con el número.
//   - count > 99 → badge muestra "99+" para no romper el layout.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/notificacion_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadNotificacionesCountProvider);
    final tieneNoLeidas = count > 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onTap,
          tooltip: 'Notificaciones',
          icon: Icon(
            tieneNoLeidas ? Icons.notifications : Icons.notifications_outlined,
          ),
        ),
        if (tieneNoLeidas)
          Positioned(
            right: 4,
            top: 4,
            child: IgnorePointer(child: _Badge(count: count)),
          ),
      ],
    );
  }
}

// ─── BADGE ───────────────────────────────────────────────────────────────────

class _Badge extends StatelessWidget {
  const _Badge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    // Cap a "99+" para que el layout del badge no crezca indefinidamente
    // cuando el usuario lleva tiempo sin abrir el panel.
    final label = count > 99 ? '99+' : '$count';

    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.brandWhite,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          height: 1.0,
        ),
      ),
    );
  }
}
