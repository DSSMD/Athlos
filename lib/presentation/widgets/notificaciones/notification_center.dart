// ============================================================================
// lib/presentation/widgets/notificaciones/notification_center.dart
// ============================================================================
// Widget SMART — el "contenido" del panel de notificaciones.
//
// Watchea notificacionesProvider + unreadNotificacionesCountProvider y
// renderiza header (título + contador + botón "marcar todas como leídas") +
// body con uno de cuatro estados: loading / error / vacío / lista.
//
// IMPORTANTE: este widget NO decide CÓMO se presenta el panel. La
// presentación (popup, dropdown, bottom sheet, drawer) la elige el caller
// en Bloque 3. Acá sólo está el CONTENIDO con su lógica interna.
//
// Ancho:
//   - desktop: máx 360 px (ConstrainedBox).
//   - mobile: full-width — el caller decide los paddings exteriores.
//
// Tap en un item: dispara marcarLeida(id) del notifier. Click-to-navigate
// queda fuera del scope de v1 (decisión SCRUM-91).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/notificacion_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/breakpoints.dart';
import '../shared/empty_state.dart';
import 'notification_item.dart';

class NotificationCenter extends ConsumerWidget {
  const NotificationCenter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificacionesProvider);
    final unread = ref.watch(unreadNotificacionesCountProvider);
    final isMobile = context.isMobile;

    final body = Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            unread: unread,
            onMarcarTodas: unread == 0
                ? null
                : () => ref
                      .read(notificacionesProvider.notifier)
                      .marcarTodasLeidas(),
          ),
          const Divider(height: 1, color: AppColors.border),
          // Body cambia según el estado del AsyncValue.
          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl3),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'Error al cargar notificaciones: $err',
                style: AppTypography.small.copyWith(color: AppColors.error),
                textAlign: TextAlign.center,
              ),
            ),
            data: (list) {
              if (list.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: EmptyState(
                    icon: Icons.notifications_none,
                    title: 'No tenés notificaciones',
                    subtitle: 'Cuando recibas alertas, las verás acá.',
                  ),
                );
              }
              // ListView.separated dentro de un container con altura limitada
              // por el caller. Acá usamos shrinkWrap para que el contenedor
              // se adapte sin scroll si la lista es chica.
              return ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 480),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: list.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: AppColors.border),
                  itemBuilder: (_, i) {
                    final n = list[i];
                    return NotificationItem(
                      notificacion: n,
                      onTap: () => ref
                          .read(notificacionesProvider.notifier)
                          .marcarLeida(n.idNotificacion),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );

    if (isMobile) {
      return body;
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: body,
    );
  }
}

// ─── HEADER ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.unread, required this.onMarcarTodas});
  final int unread;
  final VoidCallback? onMarcarTodas;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Notificaciones',
                  style: AppTypography.h3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (unread > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$unread sin leer',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // onPressed = null cuando no hay no-leídas → estado deshabilitado
          // gratis por Material (gris + sin ripple).
          TextButton(
            onPressed: onMarcarTodas,
            style: TextButton.styleFrom(foregroundColor: AppColors.primary500),
            child: const Text('Marcar todas como leídas'),
          ),
        ],
      ),
    );
  }
}
