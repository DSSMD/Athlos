// ============================================================================
// orden_detalle_page.dart
// Ubicación: lib/presentation/pages/produccion/orden_detalle_page.dart
// Descripción: Vista de detalle de una orden. Muestra workflow, información
// del pedido, items editables (escalabilidad SCRUM-72), resumen de pagos,
// fechas clave y placeholders para features que requieren joins con backend.
// Se renderiza dentro del shell como estado interno de OrdenesPage.
// ============================================================================

import 'package:flutter/material.dart';

import '../../components/ordenes/orden_items_editor.dart';
import '../../components/ordenes/orden_workflow_stepper.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import '../../../domain/models/orden_model.dart';

class OrdenDetallePage extends StatefulWidget {
  final OrdenModel orden;
  final VoidCallback onVolver;

  const OrdenDetallePage({
    super.key,
    required this.orden,
    required this.onVolver,
  });

  @override
  State<OrdenDetallePage> createState() => _OrdenDetallePageState();
}

class _OrdenDetallePageState extends State<OrdenDetallePage> {
  static const double _mobileBreakpoint = 900;

  // Items mock iniciales — la "escalabilidad" local arranca desde aquí.
  List<OrdenItem> _items = const [
    OrdenItem(nombre: 'Producto principal', cantidad: 10, precioUnitario: 25.0),
  ];

  double get _totalItems =>
      _items.fold(0, (sum, i) => sum + i.subtotal);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < _mobileBreakpoint;
        final orden = widget.orden;
        final codigoCorto = orden.numOrden.length > 8
            ? orden.numOrden.substring(0, 8).toUpperCase()
            : orden.numOrden.toUpperCase();

        return Column(
          children: [
            // Topbar con botón volver
            Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? AppSpacing.lg : AppSpacing.xl2,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: widget.onVolver,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Volver al listado'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text('#$codigoCorto', style: AppTypography.h3),
                  const SizedBox(width: AppSpacing.md),
                  _EstadoChip(idEstado: orden.idEstado),
                ],
              ),
            ),

            // Contenido scrolleable
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                  isMobile ? AppSpacing.lg : AppSpacing.xl2,
                ),
                child: isMobile
                    ? _buildMobile(orden)
                    : _buildDesktop(orden),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDesktop(OrdenModel orden) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Columna principal
        Expanded(
          flex: 3,
          child: Column(
            children: [
              OrdenWorkflowStepper(idEstado: orden.idEstado),
              const SizedBox(height: AppSpacing.xl),
              _InfoPedidoCard(orden: orden),
              const SizedBox(height: AppSpacing.xl),
              OrdenItemsEditor(
                initialItems: _items,
                onChanged: (items, _) => setState(() => _items = items),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xl),

        // Sidebar derecho
        Expanded(
          flex: 1,
          child: Column(
            children: [
              _PagosCard(totalItems: _totalItems),
              const SizedBox(height: AppSpacing.xl),
              _FechasClaveCard(orden: widget.orden),
              const SizedBox(height: AppSpacing.xl),
              const _HistorialCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobile(OrdenModel orden) {
    return Column(
      children: [
        OrdenWorkflowStepper(idEstado: orden.idEstado),
        const SizedBox(height: AppSpacing.lg),
        _InfoPedidoCard(orden: orden),
        const SizedBox(height: AppSpacing.lg),
        OrdenItemsEditor(
          initialItems: _items,
          onChanged: (items, _) => setState(() => _items = items),
        ),
        const SizedBox(height: AppSpacing.lg),
        _PagosCard(totalItems: _totalItems),
        const SizedBox(height: AppSpacing.lg),
        _FechasClaveCard(orden: widget.orden),
        const SizedBox(height: AppSpacing.lg),
        const _HistorialCard(),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ESTADO CHIP (header)
// ══════════════════════════════════════════════════════════════════════════════

class _EstadoChip extends StatelessWidget {
  final int idEstado;
  const _EstadoChip({required this.idEstado});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (idEstado) {
      1 => ('Pendiente', AppColors.warning),
      2 => ('En producción', AppColors.info),
      3 => ('Entregado', AppColors.success),
      4 => ('Cancelado', AppColors.error),
      _ => ('Estado $idEstado', AppColors.neutral500),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTypography.small.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// CARDS
// ══════════════════════════════════════════════════════════════════════════════

class _InfoPedidoCard extends StatelessWidget {
  final OrdenModel orden;
  const _InfoPedidoCard({required this.orden});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Información del pedido',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _InfoItem(
                label: 'Cliente',
                value: 'Cliente #${orden.idCliente.substring(0, 6)}',
              ),
              _InfoItem(label: 'Producto', value: '—'),
              _InfoItem(label: 'Cantidad', value: '—'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              _InfoItem(
                label: 'Fecha pedido',
                value: _formatFecha(orden.fechaOrden),
              ),
              _InfoItem(
                label: 'Fecha entrega',
                value: _formatFecha(orden.fechaEntrega),
                valueColor: AppColors.primary500,
              ),
              _InfoItem(label: 'Prioridad', value: '—'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.neutral50,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Text(
              'Especificaciones: —',
              style: AppTypography.small,
            ),
          ),
        ],
      ),
    );
  }

  String _formatFecha(DateTime f) =>
      '${f.day.toString().padLeft(2, '0')}/'
      '${f.month.toString().padLeft(2, '0')}/'
      '${f.year}';
}

class _PagosCard extends StatelessWidget {
  final double totalItems;
  const _PagosCard({required this.totalItems});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Pagos',
      child: Column(
        children: [
          _KeyValueRow(
            label: 'Total orden',
            value: 'Bs. ${totalItems.toStringAsFixed(2)}',
            bold: true,
          ),
          _KeyValueRow(label: 'Anticipo', value: '—'),
          _KeyValueRow(label: 'Método', value: '—'),
          _KeyValueRow(label: 'Fecha pago', value: '—'),
          const Divider(),
          _KeyValueRow(
            label: 'Saldo pendiente',
            value: 'Bs. ${totalItems.toStringAsFixed(2)}',
            bold: true,
            valueColor: AppColors.error,
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // TODO(SCRUM-72): conectar a flujo de pago real
              },
              child: const Text('Registrar pago'),
            ),
          ),
        ],
      ),
    );
  }
}

class _FechasClaveCard extends StatelessWidget {
  final OrdenModel orden;
  const _FechasClaveCard({required this.orden});

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Fechas clave',
      child: Column(
        children: [
          _KeyValueRow(
            label: 'Registro',
            value:
                '${orden.fechaOrden.day.toString().padLeft(2, '0')}/'
                '${orden.fechaOrden.month.toString().padLeft(2, '0')}/'
                '${orden.fechaOrden.year}',
          ),
          _KeyValueRow(
            label: 'Entrega estimada',
            value:
                '${orden.fechaEntrega.day.toString().padLeft(2, '0')}/'
                '${orden.fechaEntrega.month.toString().padLeft(2, '0')}/'
                '${orden.fechaEntrega.year}',
            valueColor: AppColors.primary500,
          ),
        ],
      ),
    );
  }
}

class _HistorialCard extends StatelessWidget {
  const _HistorialCard();

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'Historial',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Text(
          'El historial de cambios se mostrará acá cuando backend lo exponga.',
          style: AppTypography.small.copyWith(color: AppColors.textMuted),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HELPERS
// ══════════════════════════════════════════════════════════════════════════════

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.h3),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: AppTypography.body.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _KeyValueRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.small.copyWith(color: AppColors.textMuted),
          ),
          Text(
            value,
            style: AppTypography.small.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}