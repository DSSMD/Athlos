// ============================================================================
// cliente_resumen_view.dart
// Ubicación: lib/presentation/components/clientes/cliente_resumen_view.dart
// Descripción: Vista de detalle del cliente (modo solo lectura). Se muestra
// como segundo tab del drawer en modo editar. Contiene:
// - Header con avatar grande, nombre, razón social y badges.
// - Información de contacto (lectura).
// - Resumen financiero (con placeholders donde backend no expone datos).
// - Últimas órdenes (empty state hasta que backend lo conecte).
// ============================================================================

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import '../../widgets/user_avatar.dart';
import '../../../domain/models/cliente_model.dart';

class ClienteResumenView extends StatelessWidget {
  const ClienteResumenView({super.key, required this.cliente});

  final ClienteModel cliente;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HeaderCliente(cliente: cliente),
          const SizedBox(height: AppSpacing.lg),

          _InfoContactoCard(cliente: cliente),
          const SizedBox(height: AppSpacing.lg),

          _ResumenFinancieroCard(cliente: cliente),
          const SizedBox(height: AppSpacing.lg),

          const _UltimasOrdenesCard(),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HEADER — avatar + nombre + badges
// ══════════════════════════════════════════════════════════════════════════════

class _HeaderCliente extends StatelessWidget {
  const _HeaderCliente({required this.cliente});
  final ClienteModel cliente;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Avatar grande
          UserAvatar(
            name: cliente.nombreMostrable,
            size: 80,
            showPresence: false,
          ),
          const SizedBox(height: AppSpacing.md),

          // Nombre
          Text(
            cliente.nombreMostrable,
            style: AppTypography.h3,
            textAlign: TextAlign.center,
          ),

          // Razón social (si es empresa y tiene)
          if (cliente.razonSocial != null &&
              cliente.razonSocial!.isNotEmpty &&
              cliente.tipoEnum == TipoCliente.empresa) ...[
            const SizedBox(height: 2),
            Text(
              cliente.razonSocial!,
              style: AppTypography.small.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          ],

          const SizedBox(height: AppSpacing.md),

          // Badges
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _MiniBadge(
                label: cliente.activo ? 'Activo' : 'Inactivo',
                color: cliente.activo
                    ? AppColors.success
                    : AppColors.neutral500,
              ),
              _MiniBadge(label: cliente.tipoEnum.label, color: AppColors.info),
              if (cliente.esPrioritario)
                _MiniBadge(label: 'Prioritario', color: AppColors.primary500),
              if (cliente.permiteCredito)
                _MiniBadge(label: 'Crédito activo', color: AppColors.success),
            ],
          ),

          // Cliente desde
          if (cliente.createdAt != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Cliente desde: ${_fmtDate(cliente.createdAt!)}',
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// INFORMACIÓN DE CONTACTO (solo lectura)
// ══════════════════════════════════════════════════════════════════════════════

class _InfoContactoCard extends StatelessWidget {
  const _InfoContactoCard({required this.cliente});
  final ClienteModel cliente;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Información de contacto',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            icon: Icons.phone_outlined,
            label: 'Teléfono principal',
            value: cliente.numTelefono ?? '—',
          ),
          if (cliente.numTelefono2 != null && cliente.numTelefono2!.isNotEmpty)
            _InfoRow(
              icon: Icons.phone_outlined,
              label: 'Teléfono secundario',
              value: cliente.numTelefono2!,
            ),
          _InfoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: cliente.email == null || cliente.email!.isEmpty
                ? '—'
                : cliente.email!,
          ),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Dirección',
            value: cliente.direccion ?? '—',
          ),
          _InfoRow(
            icon: Icons.badge_outlined,
            label: 'NIT / CI',
            value: cliente.ciCliente.isEmpty ? '—' : cliente.ciCliente,
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// RESUMEN FINANCIERO (placeholders + crédito real)
// ══════════════════════════════════════════════════════════════════════════════

class _ResumenFinancieroCard extends StatelessWidget {
  const _ResumenFinancieroCard({required this.cliente});
  final ClienteModel cliente;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Resumen financiero',
      child: Column(
        children: [
          // TODO(SCRUM-69): conectar cuando backend exponga totales del cliente
          const _FilaMonto(label: 'Total comprado', valor: '—'),
          const _FilaMonto(label: 'Pagado', valor: '—'),
          const _FilaMonto(label: 'Deuda actual', valor: '—'),
          _FilaMonto(
            label: 'Crédito disponible',
            valor: cliente.permiteCredito
                ? 'Bs. ${cliente.limiteCredito.toStringAsFixed(2)}'
                : 'No habilitado',
            valorColor: cliente.permiteCredito
                ? AppColors.success
                : AppColors.textMuted,
          ),
          const _FilaMonto(label: 'Ticket promedio', valor: '—'),
          if (cliente.permiteCredito) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Plazo de pago: ${cliente.diasPlazoPago} días',
              style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ÚLTIMAS ÓRDENES (empty state)
// ══════════════════════════════════════════════════════════════════════════════

class _UltimasOrdenesCard extends StatelessWidget {
  const _UltimasOrdenesCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Últimas órdenes',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                size: 32,
                color: AppColors.textMuted,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Las órdenes se mostrarán cuando estén\nconectadas al sistema.',
                style: AppTypography.small.copyWith(color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HELPERS
// ══════════════════════════════════════════════════════════════════════════════

class _Card extends StatelessWidget {
  const _Card({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.small.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaMonto extends StatelessWidget {
  const _FilaMonto({required this.label, required this.valor, this.valorColor});

  final String label;
  final String valor;
  final Color? valorColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.small.copyWith(color: AppColors.textSecondary),
          ),
          Text(
            valor,
            style: AppTypography.small.copyWith(
              color: valorColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
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
        ),
      ),
    );
  }
}

String _fmtDate(DateTime d) {
  final dd = d.day.toString().padLeft(2, '0');
  final mm = d.month.toString().padLeft(2, '0');
  return '$dd/$mm/${d.year}';
}
