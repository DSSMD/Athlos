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

// lib/presentation/components/ordenes/orden_productos_card.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:workspace/domain/models/orden_model.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import 'orden_draft.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/catalogos_provider.dart';

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
              _col('PRODUCTO Y TALLA', 6),
              _col('CANTIDAD', 3),
              const SizedBox(width: 60),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        for (var i = 0; i < draft.productos.length; i++) ...[
          _ProductoRowDesktop(
            index: i + 1,
            producto: draft.productos[i],
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
  final VoidCallback onEliminar;

  const _ProductoRowDesktop({
    required this.index,
    required this.producto,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('$index', style: AppTypography.small)),
          Expanded(
            flex: 6,
            child: Text(
              producto.nombre,
              style: AppTypography.small,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              '${producto.cantidad} ${producto.unidad}',
              style: AppTypography.small,
            ),
          ),
          SizedBox(
            width: 60,
            child: Align(
              alignment: Alignment.center,
              child: IconButton(
                onPressed: onEliminar,
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.error,
                tooltip: 'Eliminar',
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
  final VoidCallback onEliminar;

  const _ProductoRowMobile({
    required this.index,
    required this.producto,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  producto.nombre,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Cantidad: ${producto.cantidad} ${producto.unidad}',
                  style: AppTypography.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onEliminar,
            icon: const Icon(Icons.delete_outline, size: 20),
            color: AppColors.error,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
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

// ═════════════════════════════════════════════════════════════════════════════
// DIALOG: Agregar producto (CONECTADO A BD)
// ═════════════════════════════════════════════════════════════════════════════
class _AgregarProductoDialog extends ConsumerStatefulWidget {
  // <-- Ahora es Consumer
  const _AgregarProductoDialog();

  @override
  ConsumerState<_AgregarProductoDialog> createState() =>
      _AgregarProductoDialogState();
}

class _AgregarProductoDialogState
    extends ConsumerState<_AgregarProductoDialog> {
  int? _idPrenda;
  String _nombrePrenda = '';

  int? _idTalla;
  String _nombreTalla = '';

  final _cantidadCtrl = TextEditingController();

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    super.dispose();
  }

  void _guardar() {
    final cantidad = int.tryParse(_cantidadCtrl.text) ?? 0;

    if (_idPrenda == null || _idTalla == null || cantidad <= 0) return;

    Navigator.pop(
      context,
      OrdenProductoItem(
        idTipoPrenda: _idPrenda,
        idTalla: _idTalla,
        nombre: '$_nombrePrenda - Talla $_nombreTalla',
        cantidad: cantidad,
        precioUnitario:
            0.0, // Lo dejamos en 0 internamente para no romper el draft
        unidad: 'uds',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prendasAsync = ref.watch(tiposPrendaProvider);
    final tallasAsync = ref.watch(tallasProvider);

    return AlertDialog(
      title: Text('Agregar producto', style: AppTypography.h3),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('Tipo de prenda *'),
            const SizedBox(height: AppSpacing.xs),
            prendasAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => const Text('Error al cargar prendas'),
              data: (prendas) => DropdownButtonFormField<int>(
                initialValue: _idPrenda,
                decoration: _decoration('Selecciona una prenda'),
                items: prendas
                    .map(
                      (p) => DropdownMenuItem<int>(
                        value: p.id,
                        child: Text(p.nombre),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _idPrenda = val;
                      _nombrePrenda = prendas
                          .firstWhere((p) => p.id == val)
                          .nombre;
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Talla *'),
                      const SizedBox(height: AppSpacing.xs),
                      tallasAsync.when(
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, s) => const Text('Error'),
                        data: (tallas) => DropdownButtonFormField<int>(
                          initialValue: _idTalla,
                          decoration: _decoration('Talla'),
                          items: tallas
                              .map(
                                (t) => DropdownMenuItem<int>(
                                  value: t['id_talla'] as int,
                                  child: Text(t['nombre_talla'].toString()),
                                ),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _idTalla = val;
                                _nombreTalla = tallas.firstWhere(
                                  (t) => t['id_talla'] == val,
                                )['nombre_talla'];
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Cantidad *'),
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
              ],
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

  Widget _label(String text) => Text(
    text,
    style: AppTypography.small.copyWith(
      color: AppColors.textSecondary,
      fontWeight: FontWeight.w500,
    ),
  );

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: AppTypography.small.copyWith(color: AppColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
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

