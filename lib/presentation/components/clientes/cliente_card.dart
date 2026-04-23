// ============================================================================
// cliente_card.dart
// Ubicación: lib/presentation/components/clientes/cliente_card.dart
// Descripción: Card de cliente para vista Mobile del listado.
// Layout vertical compacto con avatar + info + teléfono + dirección.
// Sigue el mismo patrón que user_card.dart para mantener consistencia.
// ============================================================================

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import '../../widgets/user_avatar.dart';
import '../../../domain/models/cliente_model.dart';

class ClienteCard extends StatelessWidget {
  const ClienteCard({
    super.key,
    required this.cliente,
    required this.onTap,
  });

  final ClienteModel cliente;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              // Header: avatar + nombre + CI
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  UserAvatar(
                    name: cliente.nombreCompleto,
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
                          cliente.nombreCompleto,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'CI: ${cliente.ciCliente}',
                          style: AppTypography.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Teléfono
              if (cliente.numTelefono != null)
                _InfoRow(
                  icon: Icons.phone_outlined,
                  text: cliente.numTelefono!,
                ),

              // Dirección
              if (cliente.direccion != null) ...[
                const SizedBox(height: AppSpacing.xs),
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: cliente.direccion!,
                ),
              ],

              const SizedBox(height: AppSpacing.md),

              // Footer: fecha de registro
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    cliente.createdAt != null
                        ? 'Registrado: ${cliente.createdAt!.day.toString().padLeft(2, '0')}/${cliente.createdAt!.month.toString().padLeft(2, '0')}/${cliente.createdAt!.year}'
                        : '',
                    style: AppTypography.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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