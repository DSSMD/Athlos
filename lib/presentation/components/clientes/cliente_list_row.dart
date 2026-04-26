// ============================================================================
// cliente_list_row.dart
// Ubicación: lib/presentation/components/clientes/cliente_list_row.dart
// Descripción: Fila de la tabla de Clientes para vista Desktop.
// Sigue el mismo patrón que user_list_row.dart para mantener consistencia.
//
// Columnas según Figma (pantalla 13):
// CLIENTE | NIT/CI | TELÉFONO | ÓRDENES | TOTAL COMPRADO | DEUDA |
// ÚLTIMO PEDIDO | ESTADO | Ver
//
// TODO(SCRUM-69): los campos ÓRDENES, TOTAL COMPRADO, DEUDA y ÚLTIMO PEDIDO
// requieren joins con la tabla de órdenes que aún no está conectada al
// backend. Por ahora muestran '—'. Se conectarán cuando Mel exponga los datos.
// ============================================================================

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import '../../widgets/user_avatar.dart';
import '../../../domain/models/cliente_model.dart';

class ClienteListRow extends StatefulWidget {
  const ClienteListRow({
    super.key,
    required this.cliente,
    required this.onView,
  });

  final ClienteModel cliente;
  final VoidCallback onView;

  @override
  State<ClienteListRow> createState() => _ClienteListRowState();
}

class _ClienteListRowState extends State<ClienteListRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.cliente;

    // Subtítulo: razón social si es empresa, "Cliente regular" si es persona.
    final String subtitulo = c.razonSocial != null && c.razonSocial!.isNotEmpty
        ? c.razonSocial!
        : 'Cliente regular';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        color: _hovered ? AppColors.neutral50 : Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // CLIENTE (avatar + nombre + subtítulo)
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  UserAvatar(
                    name: c.nombreMostrable,
                    size: 40,
                    showPresence: false,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          c.nombreMostrable,
                          style: AppTypography.small.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          subtitulo,
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // NIT / CI
            Expanded(
              flex: 2,
              child: Text(
                c.ciCliente.isEmpty ? '—' : c.ciCliente,
                style: AppTypography.small.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // TELÉFONO
            Expanded(
              flex: 2,
              child: Text(
                c.numTelefono ?? '—',
                style: AppTypography.small.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // ÓRDENES (placeholder)
            Expanded(
              flex: 2,
              child: Text(
                '—',
                textAlign: TextAlign.center,
                style: AppTypography.small.copyWith(color: AppColors.textMuted),
              ),
            ),

            // TOTAL COMPRADO (placeholder)
            Expanded(
              flex: 2,
              child: Text(
                '—',
                textAlign: TextAlign.center,
                style: AppTypography.small.copyWith(color: AppColors.textMuted),
              ),
            ),

            // DEUDA (placeholder)
            Expanded(
              flex: 1,
              child: Text(
                '—',
                textAlign: TextAlign.center,
                style: AppTypography.small.copyWith(color: AppColors.textMuted),
              ),
            ),

            // ÚLTIMO PEDIDO (placeholder)
            Expanded(
              flex: 2,
              child: Text(
                '—',
                textAlign: TextAlign.center,
                style: AppTypography.small.copyWith(color: AppColors.textMuted),
              ),
            ),

            // ESTADO (Activo / Inactivo)
            Expanded(flex: 2, child: _EstadoBadge(activo: c.activo)),

            // ACCIONES — botón "Ver"
            SizedBox(
              width: 70,
              child: Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: widget.onView,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Ver &\nEditar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BADGE DE ESTADO (Activo / Inactivo)
// ══════════════════════════════════════════════════════════════════════════════

class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({required this.activo});
  final bool activo;

  @override
  Widget build(BuildContext context) {
    final color = activo ? AppColors.success : AppColors.neutral500;
    final label = activo ? 'Activo' : 'Inactivo';

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
