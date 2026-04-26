// ============================================================================
// cliente_card.dart
// Ubicación: lib/presentation/components/clientes/cliente_card.dart
// Descripción: Card de cliente para vista Mobile del listado.
// Sigue el mismo patrón que user_card.dart para mantener consistencia.
//
// TODO(SCRUM-69): los datos de órdenes (cantidad, total comprado, deuda,
// último pedido) requieren joins con la tabla de órdenes que aún no está
// conectada al backend. Por ahora muestran '—'.
// ============================================================================

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import '../../widgets/user_avatar.dart';
import '../../../domain/models/cliente_model.dart';

class ClienteCard extends StatelessWidget {
  const ClienteCard({super.key, required this.cliente, required this.onTap});

  final ClienteModel cliente;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Subtítulo: razón social si es empresa, "Cliente regular" si es persona.
    final String subtitulo =
        cliente.razonSocial != null && cliente.razonSocial!.isNotEmpty
        ? cliente.razonSocial!
        : 'Cliente regular';

    return Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: avatar + nombre/subtítulo + badge estado
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserAvatar(
                    name: cliente.nombreMostrable,
                    size: 44,
                    showPresence: false,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          cliente.nombreMostrable,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
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
                  _EstadoBadge(activo: cliente.activo),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // NIT/CI
              _InfoRow(
                icon: Icons.badge_outlined,
                text: cliente.ciCliente.isEmpty
                    ? 'Sin NIT/CI'
                    : 'NIT/CI: ${cliente.ciCliente}',
              ),

              // Teléfono
              if (cliente.numTelefono != null) ...[
                const SizedBox(height: AppSpacing.xs),
                _InfoRow(
                  icon: Icons.phone_outlined,
                  text: cliente.numTelefono!,
                ),
              ],

              // Dirección
              if (cliente.direccion != null &&
                  cliente.direccion!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: cliente.direccion!,
                ),
              ],

              const Divider(height: AppSpacing.xl),

              // Datos de órdenes (placeholders por ahora)
              Row(
                children: [
                  Expanded(
                    child: _MiniStat(label: 'Órdenes', value: '—'),
                  ),
                  Expanded(
                    child: _MiniStat(label: 'Total', value: '—'),
                  ),
                  Expanded(
                    child: _MiniStat(
                      label: 'Deuda',
                      value: '—',
                      valueColor: AppColors.textMuted,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // Footer: fecha de registro
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  cliente.createdAt != null
                      ? 'Registrado: ${cliente.createdAt!.day.toString().padLeft(2, '0')}/${cliente.createdAt!.month.toString().padLeft(2, '0')}/${cliente.createdAt!.year}'
                      : '',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// SUBCOMPONENTES
// ══════════════════════════════════════════════════════════════════════════════

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            text,
            style: AppTypography.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.small.copyWith(
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({required this.activo});
  final bool activo;

  @override
  Widget build(BuildContext context) {
    final color = activo ? AppColors.success : AppColors.neutral500;
    final label = activo ? 'Activo' : 'Inactivo';

    return Container(
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
          fontSize: 10,
        ),
      ),
    );
  }
}
