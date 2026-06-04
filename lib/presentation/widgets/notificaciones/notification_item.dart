// ============================================================================
// lib/presentation/widgets/notificaciones/notification_item.dart
// ============================================================================
// Widget DUMB que renderiza una notificación en la lista del panel.
//
// No watchea providers — recibe el modelo y un onTap por props. El padre
// (NotificationCenter en este mismo bloque) es el que conecta con el
// provider y dispara marcarLeida en el tap.
//
// Diferenciación visual leída vs no-leída:
//   - !leida → titulo en bold + dot rojo a la derecha + opacidad 100 %.
//   - leida  → titulo en peso normal + sin dot + opacidad ~60 %.
//
// Tiempo relativo:
//   - Helper privado `_tiempoRelativo` con casos: segundos / minutos / horas
//     / días (< 7) y fallback a fecha absoluta usando intl en locale es_ES
//     (locale inicializado en main.dart).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../domain/models/notificacion_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class NotificationItem extends StatelessWidget {
  const NotificationItem({super.key, required this.notificacion, this.onTap});

  final NotificacionModel notificacion;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final leida = notificacion.leida;
    final colorPrioridad = _colorPrioridad(notificacion.prioridad);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Opacity(
          // Atenuamos las leídas para que las no-leídas concentren la atención.
          opacity: leida ? 0.6 : 1.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dot de prioridad — informativa/advertencia/critica.
                _Dot(color: colorPrioridad, size: 10),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notificacion.titulo ?? 'Sin título',
                        style: AppTypography.small.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: leida ? FontWeight.w500 : FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (notificacion.mensaje != null &&
                          notificacion.mensaje!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          notificacion.mensaje!,
                          style: AppTypography.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        _tiempoRelativo(notificacion.fechaCreacion),
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Indicador de no-leída — sólo si la notificación lo está.
                if (!leida) ...[
                  const SizedBox(width: AppSpacing.sm),
                  const _Dot(color: AppColors.error, size: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── HELPERS PRIVADOS ────────────────────────────────────────────────────────

/// Mapea prioridad → color saturado. Si llega null usamos un gris neutro;
/// la lógica de presentación no debería romperse por una prioridad ausente.
Color _colorPrioridad(PrioridadNotificacion? prioridad) {
  switch (prioridad) {
    case PrioridadNotificacion.informativa:
      return AppColors.info;
    case PrioridadNotificacion.advertencia:
      return AppColors.warning;
    case PrioridadNotificacion.critica:
      return AppColors.error;
    case null:
      return AppColors.neutral400;
  }
}

/// Tiempo relativo en español. Para fechas > 7 días caemos a la fecha
/// absoluta formateada con intl (locale es_ES inicializado en main.dart).
String _tiempoRelativo(DateTime fecha) {
  final ahora = DateTime.now();
  final diff = ahora.difference(fecha);

  if (diff.isNegative) {
    // Defensa: una fecha futura no debería pasar, pero si pasa mostramos
    // la fecha absoluta en lugar de "hace -X".
    return DateFormat('d MMM yyyy', 'es_ES').format(fecha);
  }
  if (diff.inSeconds < 60) return 'hace unos segundos';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  if (diff.inDays < 7) {
    return diff.inDays == 1 ? 'hace 1 día' : 'hace ${diff.inDays} días';
  }
  return DateFormat('d MMM yyyy', 'es_ES').format(fecha);
}

/// Dot circular reutilizable usado tanto para prioridad como para no-leída.
class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      // Margen vertical chico para alinear con la primera línea de texto.
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
