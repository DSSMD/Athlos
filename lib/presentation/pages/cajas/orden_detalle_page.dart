import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../components/ordenes/orden_items_editor.dart';
import '../../components/ordenes/orden_workflow_stepper.dart';
import '../../components/ordenes/orden_produccion_pagos_card.dart'; // 💰 Pagos a producción

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/breakpoints.dart';

import '../../widgets/shared/mobile_screen_header.dart';

import '../../../domain/models/orden_model.dart';
import '../../../domain/models/auditoria_orden_model.dart';
import '../../providers/orden_provider.dart';

class OrdenDetallePage extends ConsumerStatefulWidget {
  final OrdenModel orden;
  final VoidCallback onVolver;

  const OrdenDetallePage({
    super.key,
    required this.orden,
    required this.onVolver,
  });

  @override
  ConsumerState<OrdenDetallePage> createState() => _OrdenDetallePageState();
}

class _OrdenDetallePageState extends ConsumerState<OrdenDetallePage> {
  late List<OrdenItem> _items;

  @override
  void initState() {
    super.initState();

    // Construir items visuales desde detalleOrden (esquema nuevo).
    // Cada talla de cada detalle = una fila visual con prefix del nombre del ítem
    // (sea conjunto o plantilla suelta).
    _items = widget.orden.detalleOrden.expand((detalle) {
      return detalle.tallas.map((talla) {
        return OrdenItem(
          nombre: '${detalle.nombreItem} - Talla ${talla.nombreTalla}',
          cantidad: talla.cantidad,
          precioUnitario: detalle.precioUnitario,
        );
      });
    }).toList();

    // Fallback de emergencia: si la orden no tiene detalleOrden poblado
    // (caso degenerado de datos legacy o orden incompleta), mostramos un
    // solo ítem agregado con el total general.
    if (_items.isEmpty) {
      _items = [
        OrdenItem(
          nombre: widget.orden.producto,
          cantidad: widget.orden.cantidad,
          precioUnitario: widget.orden.cantidad > 0
              ? (widget.orden.costoTotal / widget.orden.cantidad)
              : 0.0,
        ),
      ];
    }
  }

  // 💰 El total financiero SIEMPRE viene del modelo (BD), no de los ítems calculados.
  double get _totalItems => widget.orden.costoTotal;

  @override
  Widget build(BuildContext context) {
    // Migrated to AppBreakpoints.mobile (1100). Was previously: 900.
    final isMobile = context.isMobile;
    final orden = widget.orden;
    final codigoCorto = orden.numOrden.length > 8
        ? orden.numOrden.substring(0, 8).toUpperCase()
        : orden.numOrden.toUpperCase();

    return Column(
      children: [
        // Topbar con botón volver. Mobile usa MobileScreenHeader (header
        // oscuro del design system, mismo que Clientes/Usuarios/Órdenes/
        // Inventario). Desktop mantiene su Container blanco con el botón
        // de texto "Volver al listado" (look anterior).
        if (isMobile)
          MobileScreenHeader(
            title: '#$codigoCorto',
            showBackButton: true,
            onBack: widget.onVolver,
            showAvatar: false,
            trailing: _EstadoChip(idEstado: orden.idEstado),
          )
        else
          Container(
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl2,
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
            padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl2),
            child: isMobile ? _buildMobile(orden) : _buildDesktop(orden),
          ),
        ),
      ],
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
                onChanged: (items, _) {
                  // Solo agregamos ítems nuevos; no sobreescribimos los existentes
                  // para evitar que precios calculados se pierdan
                  if (items.length > _items.length) {
                    setState(() => _items = items);
                  }
                },
                onAgregarItem: (nuevoItem) async {
                  await ref
                      .read(ordenesProvider.notifier)
                      .agregarItemsAOrden(
                        numOrden: widget.orden.numOrden,
                        nuevosItems: [nuevoItem],
                      );
                },
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
              _PagosCard(orden: widget.orden, totalItems: _totalItems),
              const SizedBox(height: AppSpacing.xl),
              _FechasClaveCard(orden: widget.orden),
              const SizedBox(height: AppSpacing.xl),
              _HistorialCard(numOrden: widget.orden.numOrden),
              const SizedBox(height: AppSpacing.xl),
              // 💰 Pagos a Producción — resumen por trabajador desde la VIEW de Supabase
              OrdenProduccionPagosCard(numOrden: widget.orden.numOrden),
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
          onChanged: (items, _) {
            if (items.length > _items.length) {
              setState(() => _items = items);
            }
          },
          onAgregarItem: (nuevoItem) async {
            await ref
                .read(ordenesProvider.notifier)
                .agregarItemsAOrden(
                  numOrden: widget.orden.numOrden,
                  nuevosItems: [nuevoItem],
                );
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        _PagosCard(orden: widget.orden, totalItems: _totalItems),
        const SizedBox(height: AppSpacing.lg),
        _FechasClaveCard(orden: widget.orden),
        const SizedBox(height: AppSpacing.lg),
        _HistorialCard(numOrden: widget.orden.numOrden),
        const SizedBox(height: AppSpacing.lg),
        // 💰 Pagos a Producción — resumen por trabajador desde la VIEW de Supabase
        OrdenProduccionPagosCard(numOrden: widget.orden.numOrden),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// ESTADO CHIP (header) — Sincronizado con Workflow de 4 pasos
// ══════════════════════════════════════════════════════════════════════════════

class _EstadoChip extends StatelessWidget {
  final int idEstado;
  const _EstadoChip({required this.idEstado});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (idEstado) {
      1 => ('Pendiente', AppColors.warning),
      2 => ('En Producción', AppColors.info),
      3 => ('Finalizada', Colors.teal),
      4 => ('Entregada', AppColors.success),
      _ => ('Estado $idEstado', AppColors.neutral500),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.small.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// COMPONENTES DE LA PÁGINA DE DETALLE DE ORDEN
// ══════════════════════════════════════════════════════════════════════════════

class _PagosCard extends ConsumerWidget {
  final OrdenModel orden;
  final double totalItems;

  const _PagosCard({required this.orden, required this.totalItems});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final double total = orden.costoTotal;

    // Escuchamos los pagos de esta orden en específico
    final pagosAsync = ref.watch(pagosOrdenProvider(orden.numOrden));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: pagosAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Text(
          'Error al cargar pagos: $e',
          style: AppTypography.small.copyWith(color: AppColors.error),
        ),
        data: (pagos) {
          // Calculamos el total pagado sumando los montos de la tabla pago_cliente
          final totalPagado = pagos.fold<double>(
            0,
            (sum, pago) => sum + (pago['monto'] as num).toDouble(),
          );

          final saldoPendiente = total - totalPagado;
          final estaPagado = saldoPendiente <= 0;

          void mostrarDialogoPago(
            BuildContext context,
            WidgetRef ref,
            double saldoPendiente,
          ) {
            final montoCtrl = TextEditingController(
              text: saldoPendiente.toStringAsFixed(2),
            );
            String metodoSel = 'Efectivo';
            bool guardando = false;

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => StatefulBuilder(
                builder: (context, setStateModal) {
                  return AlertDialog(
                    title: Text(
                      'Registrar Nuevo Pago',
                      style: AppTypography.h3,
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saldo actual: Bs. ${saldoPendiente.toStringAsFixed(2)}',
                          style: AppTypography.small,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        TextField(
                          controller: montoCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Monto a pagar (Bs)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        DropdownButtonFormField<String>(
                          initialValue: metodoSel,
                          decoration: const InputDecoration(
                            labelText: 'Método',
                            border: OutlineInputBorder(),
                          ),
                          items:
                              [
                                    'Efectivo',
                                    'Transferencia',
                                    'Tarjeta',
                                    'Cheque',
                                    'QR',
                                  ]
                                  .map(
                                    (m) => DropdownMenuItem(
                                      value: m,
                                      child: Text(m),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => setStateModal(() => metodoSel = v!),
                        ),
                      ],
                    ),
                    actions: [
                      if (!guardando)
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancelar'),
                        ),
                      ElevatedButton(
                        onPressed: guardando
                            ? null
                            : () async {
                                final monto =
                                    double.tryParse(montoCtrl.text) ?? 0;
                                if (monto <= 0) return;

                                setStateModal(() => guardando = true);
                                try {
                                  // Llamamos a nuestro nuevo RPC en Supabase
                                  await Supabase.instance.client.rpc(
                                    'registrar_pago_orden',
                                    params: {
                                      'p_id_orden': orden.numOrden,
                                      'p_id_cliente': orden.idCliente,
                                      'p_monto': monto,
                                      'p_metodo_pago': metodoSel,
                                    },
                                  );

                                  // ✨ LA MAGIA DE RIVERPOD: Invalidamos el provider para que la UI se refresque sola
                                  ref.invalidate(
                                    pagosOrdenProvider(orden.numOrden),
                                  );

                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(ctx).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Pago registrado correctamente',
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  setStateModal(() => guardando = false);
                                  // ignore: use_build_context_synchronously
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },
                        child: guardando
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Confirmar Pago'),
                      ),
                    ],
                  );
                },
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Resumen Financiero', style: AppTypography.smallBold),
              const SizedBox(height: AppSpacing.md),

              _FinRow(
                label: 'Costo Total',
                value: 'Bs. ${total.toStringAsFixed(2)}',
                isBold: true,
                color: AppColors.textPrimary,
              ),
              const SizedBox(height: AppSpacing.xs),

              _FinRow(
                label: 'Total Pagado (Anticipo)',
                value: 'Bs. ${totalPagado.toStringAsFixed(2)}',
                color: AppColors.success,
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Divider(height: 1),
              ),

              _FinRow(
                label: 'Saldo Pendiente',
                value:
                    'Bs. ${(saldoPendiente > 0 ? saldoPendiente : 0).toStringAsFixed(2)}',
                isBold: true,
                color: estaPagado ? AppColors.success : AppColors.primary500,
              ),
              const SizedBox(height: AppSpacing.xs),

              _FinRow(
                label: 'Estado de Caja',
                value: estaPagado
                    ? 'PAGADO TOTALMENTE'
                    : (totalPagado > 0 ? 'CON ANTICIPO' : 'PENDIENTE'),
                isSuccess: estaPagado,
                color: estaPagado ? AppColors.success : AppColors.warning,
              ),

              if (!estaPagado) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        mostrarDialogoPago(context, ref, saldoPendiente),
                    icon: const Icon(Icons.add_card),
                    label: const Text('Registrar Anticipo / Pago'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary500,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],

              if (estaPagado && orden.idEstado == 3) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: _ConfirmarEntregaButton(orden: orden),
                ),
              ],

              // Lista de transacciones (Si el cliente dio anticipos)
              if (pagos.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Historial de Transacciones',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                ...pagos.map((pago) {
                  final fechaRaw = DateTime.parse(
                    pago['fecha_pago'].toString(),
                  );
                  final fechaStr =
                      '${fechaRaw.day.toString().padLeft(2, '0')}/${fechaRaw.month.toString().padLeft(2, '0')}/${fechaRaw.year}';
                  final metodo = pago['metodo_pago'] ?? 'No especificado';
                  final monto = (pago['monto'] as num).toDouble();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.payments_outlined,
                              size: 14,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$fechaStr - $metodo',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                        Text(
                          '+ Bs. ${monto.toStringAsFixed(2)}',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _FinRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final bool isSuccess;
  final Color? color;

  const _FinRow({
    required this.label,
    required this.value,
    this.isBold = false,
    this.isSuccess = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final style = isBold
        ? AppTypography.body.copyWith(fontWeight: FontWeight.w700)
        : AppTypography.small;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style.copyWith(color: AppColors.textSecondary)),
          Text(
            value,
            style: style.copyWith(
              color: color ?? (isSuccess ? AppColors.success : null),
            ),
          ),
        ],
      ),
    );
  }
}

// =═════════════════════════════════════════════════════════════════════════════
// CARD DE INFORMACIÓN DEL PEDIDO (con imagen modelo y datos del cliente)
// ══════════════════════════════════════════════════════════════════════════════

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

// ══════════════════════════════════════════════════════════════════════════════
// CARD DE HISTORIAL DE CAMBIOS (placeholder para futura integración con backend)
// ══════════════════════════════════════════════════════════════════════════════

class _HistorialCard extends ConsumerWidget {
  final String numOrden;
  const _HistorialCard({required this.numOrden});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historialAsync = ref.watch(historialOrdenProvider(numOrden));

    return _Card(
      title: 'Historial',
      child: historialAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Text(
            'Error al cargar el historial: $e',
            style: AppTypography.small.copyWith(color: AppColors.error),
          ),
        ),
        data: (List<AuditoriaOrdenModel> logs) {
          if (logs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Text(
                'Sin registros de cambios aún.',
                style: AppTypography.small.copyWith(color: AppColors.textMuted),
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: logs.map((log) {
              final fecha = log.fechaCambio;
              final fechaStr =
                  '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year} '
                  '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';

              final estAnt = log.estadoAnteriorNombre ?? 'Pendiente';
              final estNue = log.estadoNuevoNombre ?? 'Pendiente';

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary500,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                log.usuarioNombre ?? 'Sistema / Obrero',
                                style: AppTypography.smallBold,
                              ),
                              Text(
                                fechaStr,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            log.descripcionDetalle ?? 'Cambio de estado',
                            style: AppTypography.small,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.neutral50,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(
                              '$estAnt → $estNue',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
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

class _KeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _KeyValueRow({
    required this.label,
    required this.value,
    // ignore: unused_element_parameter
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

// ══════════════════════════════════════════════════════════════════════════════
// TARJETA DE INFORMACIÓN DEL PEDIDO (Con Imagen Modelo)
// ══════════════════════════════════════════════════════════════════════════════

class _InfoPedidoCard extends StatelessWidget {
  final OrdenModel orden;
  const _InfoPedidoCard({required this.orden});

  // Función helper para validar si un string es nulo o vacío
  String _validateText(String? text, String fallback) {
    if (text == null || text.trim().isEmpty) return fallback;
    return text;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person_pin_outlined,
                color: AppColors.primary500,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Información del Cliente y Referencia',
                style: AppTypography.h3,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. IMAGEN DE REFERENCIA (Modelo) Interactiva
              _visorImagen(context),

              const SizedBox(width: AppSpacing.xl),

              // 2. GRILLA DE DATOS DEL CLIENTE
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.xl2,
                      runSpacing: AppSpacing.lg,
                      children: [
                        _itemDato(
                          'Nombre del Cliente',
                          _validateText(orden.clienteNombre, 'No registrado'),
                          Icons.person_outline,
                        ),
                        _itemDato(
                          'CI / NIT',
                          _validateText(orden.clienteCi, 'No registrado'),
                          Icons.badge_outlined,
                        ),
                        _itemDato(
                          'Teléfono',
                          _validateText(orden.clienteTelefono, 'Sin contacto'),
                          Icons.phone_android_outlined,
                        ),
                        _itemDato(
                          'Correo Electrónico',
                          _validateText(orden.clienteEmail, 'Sin correo'),
                          Icons.alternate_email,
                        ),
                        _itemDato(
                          'Dirección de Entrega',
                          _validateText(
                            orden.clienteDireccion,
                            'Recojo en tienda',
                          ),
                          Icons.location_on_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const Divider(height: 1),
                    const SizedBox(height: AppSpacing.md),

                    // NOTAS ADICIONALES DE LA ORDEN
                    Text(
                      'Notas y especificaciones de la orden:',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      orden.notasAdicionales.isEmpty
                          ? 'Sin notas adicionales para esta orden.'
                          : orden.notasAdicionales,
                      style: AppTypography.body.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget para la imagen del modelo (Con Hover y Click)
  Widget _visorImagen(BuildContext context) {
    final bool hasImage =
        orden.imagenModelo != null && orden.imagenModelo!.isNotEmpty;

    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: hasImage
          ? Material(
              // Material necesario para el InkWell
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.md),
                onTap: () =>
                    _mostrarImagenAmpliada(context, orden.imagenModelo!),
                // StateState para manejar el hover (HoverBuilder es una buena alternativa si tienes un paquete, aquí usamos State normal a través de un StatefulWidget interno)
                child: _HoverImageWidget(imageUrl: orden.imagenModelo!),
              ),
            )
          : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_outlined,
                  color: AppColors.textMuted,
                  size: 32,
                ),
                SizedBox(height: 4),
                Text('Sin imagen', style: AppTypography.caption),
              ],
            ),
    );
  }

  // Dialog para mostrar la imagen en grande (pero sin ocupar toda la pantalla)
  void _mostrarImagenAmpliada(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Contenedor de la imagen ampliada
              Container(
                constraints: BoxConstraints(
                  // Limita el tamaño al 70% de la pantalla para que no sea gigante
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                  maxWidth: MediaQuery.of(context).size.width * 0.7,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain, // Mantiene la proporción sin recortar
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary500,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stack) => Container(
                      color: AppColors.background,
                      padding: const EdgeInsets.all(AppSpacing.xl2),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: AppSpacing.sm),
                          Text('Error al cargar la imagen ampliada'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Botón de cerrar (X) en la esquina superior derecha
              Positioned(
                top: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors
                          .black54, // Fondo oscuro semi-transparente para que se vea sobre cualquier imagen
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Widget auxiliar para cada dato individual
  Widget _itemDato(String label, String value, IconData icon) {
    return SizedBox(
      width: 220, // Ancho fijo para mantener la grilla ordenada
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.textMuted.withValues(alpha: 0.7),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGET INTERNO: Imagen con Efecto Hover
// ══════════════════════════════════════════════════════════════════════════════
class _HoverImageWidget extends StatefulWidget {
  final String imageUrl;

  const _HoverImageWidget({required this.imageUrl});

  @override
  State<_HoverImageWidget> createState() => _HoverImageWidgetState();
}

class _HoverImageWidgetState extends State<_HoverImageWidget> {
  bool _isHovered = false;
 
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.zoomIn, // Cambia el cursor a una lupa
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen Base
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Image.network(
              widget.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => const Icon(
                Icons.broken_image_outlined,
                color: AppColors.textMuted,
              ),
            ),
          ),
 
          // Capa Oscura (Aparece en Hover)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: _isHovered ? 1.0 : 0.0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Center(
                child: Icon(
                  Icons.zoom_in, // Ícono de lupa
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WIDGET INTERNO: BOTÓN DE CONFIRMAR ENTREGA (Auditoría integrada)
// ══════════════════════════════════════════════════════════════════════════════
class _ConfirmarEntregaButton extends StatefulWidget {
  final OrdenModel orden;
  const _ConfirmarEntregaButton({required this.orden});

  @override
  State<_ConfirmarEntregaButton> createState() => _ConfirmarEntregaButtonState();
}

class _ConfirmarEntregaButtonState extends State<_ConfirmarEntregaButton> {
  bool _isDelivering = false;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return ElevatedButton.icon(
          onPressed: _isDelivering
              ? null
              : () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: AppColors.brandWhite,
                      title: Text(
                        'Confirmar Entrega',
                        style: AppTypography.h3,
                      ),
                      content: Text(
                        '¿Está seguro de marcar este pedido como ENTREGADO? '
                        'Esta acción cambiará el estado de la orden y registrará la entrega.',
                        style: AppTypography.body,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Confirmar'),
                        ),
                      ],
                    ),
                  );

                  if (confirm != true) return;

                  setState(() => _isDelivering = true);

                  try {
                    final service = ref.read(ordenServiceProvider);
                    await service.actualizarEstadoOrden(
                      widget.orden.numOrden,
                      4, // 4 = Entregada
                      descripcion: 'Pedido entregado al cliente por confirmar entrega en caja.',
                    );

                    // Refrescar órdenes e historial
                    ref.invalidate(ordenesProvider);
                    ref.invalidate(historialOrdenProvider(widget.orden.numOrden));

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Pedido marcado como ENTREGADO con éxito'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error al entregar pedido: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isDelivering = false);
                  }
                },
          icon: _isDelivering
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.local_shipping),
          label: Text(
            'Confirmar Entrega',
            style: AppTypography.small.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
        );
      },
    );
  }
}
