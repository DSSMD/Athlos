// ============================================================================
// orden_productos_card.dart
// Ubicación: lib/presentation/components/ordenes/orden_productos_card.dart
// Descripción: Card "Productos de la orden" del form Crear Orden (SCRUM-75).
//
// Desktop (>= 600px del card): tabla con # / Producto / Cantidad / P. Unit /
// Subtotal / Eliminar.
// Mobile (< 600px): lista de mini-cards apiladas verticalmente con la misma
// info, formato más legible.
//
// Reusa OrdenProductoItem de orden_draft.dart.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import 'orden_draft.dart';

class OrdenProductosCard extends StatelessWidget {
  final OrdenDraft draft;
  final ValueChanged<OrdenDraft> onChanged;

  const OrdenProductosCard({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  // Breakpoint interno: por debajo, switch a layout vertical de cards.
  static const double _compactBreakpoint = 600;

  // ═══════════════════════════════════════════════════════════════════════════
  // ACCIONES
  // ═══════════════════════════════════════════════════════════════════════════
  Future<void> _agregarProducto(BuildContext context) async {
    final nuevo = await showDialog<OrdenProductoItem>(
      context: context,
      builder: (ctx) => const _AgregarProductoDialog(),
    );
    if (nuevo != null) {
      onChanged(draft.copyWith(productos: [...draft.productos, nuevo]));
    }
  }

  void _eliminarProducto(int index) {
    final nuevaLista = [...draft.productos]..removeAt(index);
    onChanged(draft.copyWith(productos: nuevaLista));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < _compactBreakpoint;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(context, isCompact),
              const SizedBox(height: AppSpacing.lg),
              if (draft.productos.isEmpty)
                _empty()
              else if (isCompact)
                _listaMobile()
              else
                _tablaDesktop(),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER — adapta el botón a icon-only en compact
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _header(BuildContext context, bool isCompact) {
    return Row(
      children: [
        Expanded(child: Text('Productos de la orden', style: AppTypography.h3)),
        const SizedBox(width: AppSpacing.sm),
        if (isCompact)
          IconButton(
            onPressed: () => _agregarProducto(context),
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.primary500,
            tooltip: 'Agregar producto',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          )
        else
          TextButton.icon(
            onPressed: () => _agregarProducto(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Agregar producto'),
            style: TextButton.styleFrom(foregroundColor: AppColors.primary500),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EMPTY STATE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _empty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl2),
      alignment: Alignment.center,
      child: Column(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 32,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'No hay productos en la orden',
            style: AppTypography.small.copyWith(color: AppColors.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            'Agregá productos con el botón de arriba',
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TABLA DESKTOP
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _tablaDesktop() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Row(
            children: [
              _col('#', 1),
              _col('PRODUCTO', 4),
              _col('CANTIDAD', 2),
              _col('P. UNITARIO', 2),
              _col('SUBTOTAL', 2),
              const SizedBox(width: 60),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        for (var i = 0; i < draft.productos.length; i++) ...[
          _ProductoRowDesktop(
            index: i + 1,
            producto: draft.productos[i],
            moneda: draft.moneda,
            onEliminar: () => _eliminarProducto(i),
          ),
          if (i < draft.productos.length - 1)
            const Divider(height: 1, color: AppColors.border),
        ],
      ],
    );
  }

  Widget _col(String label, int flex) => Expanded(
    flex: flex,
    child: Text(
      label,
      style: AppTypography.caption.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textMuted,
        letterSpacing: 0.5,
      ),
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // LISTA MOBILE — cada producto como mini-card
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _listaMobile() {
    return Column(
      children: [
        for (var i = 0; i < draft.productos.length; i++) ...[
          _ProductoRowMobile(
            index: i + 1,
            producto: draft.productos[i],
            moneda: draft.moneda,
            onEliminar: () => _eliminarProducto(i),
          ),
          if (i < draft.productos.length - 1)
            const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// FILA DESKTOP
// ═════════════════════════════════════════════════════════════════════════════
class _ProductoRowDesktop extends StatelessWidget {
  final int index;
  final OrdenProductoItem producto;
  final OrdenMoneda moneda;
  final VoidCallback onEliminar;

  const _ProductoRowDesktop({
    required this.index,
    required this.producto,
    required this.moneda,
    required this.onEliminar,
  });

  String _formatPrecio(double v) {
    if (moneda == OrdenMoneda.dolares) {
      return '\$${v.toStringAsFixed(2)}';
    }
    return 'Bs. ${v.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('$index', style: AppTypography.small)),
          Expanded(
            flex: 4,
            child: Text(
              producto.nombre,
              style: AppTypography.small,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${producto.cantidad} ${producto.unidad}',
              style: AppTypography.small,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatPrecio(producto.precioUnitario),
              style: AppTypography.small,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatPrecio(producto.subtotal),
              style: AppTypography.small.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 60,
            child: Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: onEliminar,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.error,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Eliminar',
                  style: AppTypography.small.copyWith(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// FILA MOBILE — mini-card vertical
// ═════════════════════════════════════════════════════════════════════════════
class _ProductoRowMobile extends StatelessWidget {
  final int index;
  final OrdenProductoItem producto;
  final OrdenMoneda moneda;
  final VoidCallback onEliminar;

  const _ProductoRowMobile({
    required this.index,
    required this.producto,
    required this.moneda,
    required this.onEliminar,
  });

  String _formatPrecio(double v) {
    if (moneda == OrdenMoneda.dolares) {
      return '\$${v.toStringAsFixed(2)}';
    }
    return 'Bs. ${v.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Línea 1: #N + nombre + botón eliminar
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary500.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$index',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.primary500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  producto.nombre,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: onEliminar,
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.error,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Eliminar',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Línea 2: cantidad y precio unitario
          Row(
            children: [
              Expanded(
                child: _miniInfo(
                  label: 'Cantidad',
                  value: '${producto.cantidad} ${producto.unidad}',
                ),
              ),
              Expanded(
                child: _miniInfo(
                  label: 'P. unitario',
                  value: _formatPrecio(producto.precioUnitario),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.sm),
          // Línea 3: subtotal destacado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal',
                style: AppTypography.small.copyWith(color: AppColors.textMuted),
              ),
              Text(
                _formatPrecio(producto.subtotal),
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniInfo({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.small.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DIALOG: Agregar producto
// ═════════════════════════════════════════════════════════════════════════════
class _AgregarProductoDialog extends StatefulWidget {
  const _AgregarProductoDialog();

  @override
  State<_AgregarProductoDialog> createState() => _AgregarProductoDialogState();
}

class _AgregarProductoDialogState extends State<_AgregarProductoDialog> {
  final _nombreCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();
  final _precioCtrl = TextEditingController();
  String _unidad = 'uds';

  static const List<String> _unidades = ['uds', 'mts', 'kg', 'cajas', 'pares'];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _cantidadCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    final nombre = _nombreCtrl.text.trim();
    final cantidad = int.tryParse(_cantidadCtrl.text) ?? 0;
    final precio = double.tryParse(_precioCtrl.text) ?? 0;
    if (nombre.isEmpty || cantidad <= 0 || precio <= 0) return;

    Navigator.pop(
      context,
      OrdenProductoItem(
        nombre: nombre,
        cantidad: cantidad,
        precioUnitario: precio,
        unidad: _unidad,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Agregar producto', style: AppTypography.h3),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Nombre del producto'),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _nombreCtrl,
              decoration: _decoration('Ej: Pantalones cargo'),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Cantidad'),
                      const SizedBox(height: AppSpacing.xs),
                      TextField(
                        controller: _cantidadCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: _decoration('0'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Unidad'),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _unidad,
                            isExpanded: true,
                            items: _unidades
                                .map(
                                  (u) => DropdownMenuItem(
                                    value: u,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                      ),
                                      child: Text(u),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _unidad = v);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _label('Precio unitario'),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              controller: _precioCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: _decoration('0.00'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _guardar,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary500,
            foregroundColor: Colors.white,
          ),
          child: const Text('Agregar'),
        ),
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: AppTypography.small.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.small.copyWith(color: AppColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: AppColors.primary500),
      ),
    );
  }
}
