// ============================================================================
// cliente_list_row.dart
// Ubicación: lib/presentation/components/clientes/cliente_list_row.dart
// Descripción: Fila de la tabla de Clientes para vista Desktop.
// Muestra: avatar + nombre, CI, teléfono, dirección, fecha registro, editar.
// Sigue el mismo patrón que user_list_row.dart para mantener consistencia.
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
    required this.onEdit,
  });

  final ClienteModel cliente;
  final VoidCallback onEdit;

  @override
  State<ClienteListRow> createState() => _ClienteListRowState();
}

class _ClienteListRowState extends State<ClienteListRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.cliente;
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
            // CLIENTE (avatar + nombre completo)
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  UserAvatar(
                    name: c.nombreCompleto,
                    size: 40,
                    showPresence: false,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      c.nombreCompleto,
                      style: AppTypography.small.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // CI
            Expanded(
              flex: 2,
              child: Text(
                c.ciCliente,
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
            // DIRECCIÓN
            Expanded(
              flex: 3,
              child: Text(
                c.direccion ?? '—',
                style: AppTypography.small.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // REGISTRADO
            Expanded(
              flex: 2,
              child: Text(
                c.createdAt != null
                    ? '${c.createdAt!.day.toString().padLeft(2, '0')}/${c.createdAt!.month.toString().padLeft(2, '0')}/${c.createdAt!.year}'
                    : '—',
                style: AppTypography.small.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // ACCIONES
            SizedBox(
              width: 80,
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: widget.onEdit,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Editar'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}