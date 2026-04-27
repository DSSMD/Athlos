// ============================================================================
// orden_productos_card.dart
// Ubicación: lib/presentation/components/ordenes/orden_productos_card.dart
// Descripción: Card "Productos de la orden" del form Crear Orden (SCRUM-75).
// Tabla con # / Producto / Cantidad / P. Unitario / Subtotal / Eliminar.
// Botón "+ Agregar producto" abre un dialog para agregar nuevos items.
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
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(context),
          const SizedBox(height: AppSpacing.lg),
          if (draft.productos.isEmpty) _empty() else _tabla(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER — título + botón "+ Agregar producto"
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _header(BuildContext context) {
    return Row(
      children: [
        Text('Productos de la orden', style: AppTypography.h3),
        const Spacer(),
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
  // TABLA
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _tabla() {
    return Column(
      children: [
        _headerTabla(),
        const Divider(height: 1, color: AppColors.border),
        for (var i = 0; i < draft.productos.length; i++) ...[
          _ProductoRow(
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

  Widget _headerTabla() {
    return Padding(
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
}

// ═════════════════════════════════════════════════════════════════════════════
// FILA DE PRODUCTO
// ═════════════════════════════════════════════════════════════════════════════
class _ProductoRow extends StatelessWidget {
  final int index;
  final OrdenProductoItem producto;
  final OrdenMoneda moneda;
  final VoidCallback onEliminar;

  const _ProductoRow({
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
