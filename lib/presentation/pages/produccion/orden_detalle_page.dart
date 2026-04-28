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

  late List<OrdenItem> _items;

  @override
  void initState() {
    super.initState();
    // Distribuimos el costoTotal equitativamente entre tallas para que
    // el resumen financiero muestre datos reales desde el primer render.
    final totalCantidad = widget.orden.desgloseTallas
        .fold<int>(0, (sum, t) => sum + t.cantidad);
    final precioPorUnidad =
        totalCantidad > 0 ? widget.orden.costoTotal / totalCantidad : 0.0;

    _items = widget.orden.desgloseTallas.map((talla) {
      return OrdenItem(
        nombre: '${talla.nombrePrenda} - Talla ${talla.nombreTalla}',
        cantidad: talla.cantidad,
        precioUnitario: precioPorUnidad,
      );
    }).toList();

    // Fallback: Si la orden no tiene tallas, usamos el producto como item genérico
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

  double get _totalItems => _items.fold(0, (sum, i) => sum + i.subtotal);

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
                child: isMobile ? _buildMobile(orden) : _buildDesktop(orden),
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
              _PagosCard(orden: widget.orden, totalItems: _totalItems),
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
        _PagosCard(orden: widget.orden, totalItems: _totalItems),
        const SizedBox(height: AppSpacing.lg),
        _FechasClaveCard(orden: widget.orden),
        const SizedBox(height: AppSpacing.lg),
        const _HistorialCard(),
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

class _PagosCard extends StatelessWidget {
  final OrdenModel orden;
  final double totalItems;
  const _PagosCard({required this.orden, required this.totalItems});

  @override
  Widget build(BuildContext context) {
    // Si el usuario editó ítems con precios propios, usamos ese total;
    // de lo contrario mostramos el costoTotal registrado en el modelo.
    final double total =
        totalItems > 0 ? totalItems : orden.costoTotal;
    final bool pagado = orden.idEstadoPago != 1; // 1 = pendiente de pago

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
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
            label: 'Estado de Pago',
            value: orden.estadoPago,
            isSuccess: pagado,
            color: pagado ? AppColors.success : AppColors.warning,
          ),
        ],
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
                color: Colors.black.withOpacity(0.4), // Oscurece al 40%
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
