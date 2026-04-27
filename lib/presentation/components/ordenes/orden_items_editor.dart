// ============================================================================
// orden_items_editor.dart
// Ubicación: lib/presentation/components/ordenes/orden_items_editor.dart
// Descripción: Editor reactivo de items de una orden. Cumple con SCRUM-72
// ("Escalabilidad"): permite agregar items y ver el total actualizado
// localmente sin depender del backend.
// ============================================================================

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Item visual de una orden (mock, mientras backend no exponga la tabla real).
class OrdenItem {
  final String nombre;
  final int cantidad;
  final double precioUnitario;

  const OrdenItem({
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get subtotal => cantidad * precioUnitario;
}

class OrdenItemsEditor extends StatefulWidget {
  /// Lista inicial de items (puede venir vacía o pre-cargada con mock).
  final List<OrdenItem> initialItems;

  /// Callback que se dispara cuando cambia la lista de items.
  /// Útil para que el padre reciba el nuevo total.
  final void Function(List<OrdenItem> items, double nuevoTotal)? onChanged;

  const OrdenItemsEditor({
    super.key,
    this.initialItems = const [],
    this.onChanged,
  });

  @override
  State<OrdenItemsEditor> createState() => _OrdenItemsEditorState();
}

class _OrdenItemsEditorState extends State<OrdenItemsEditor> {
  late List<OrdenItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
  }

  double get _totalGeneral =>
      _items.fold(0, (sum, item) => sum + item.subtotal);

  void _agregarItem(OrdenItem item) {
    setState(() => _items.add(item));
    widget.onChanged?.call(_items, _totalGeneral);
  }

  void _eliminarItem(int index) {
    setState(() => _items.removeAt(index));
    widget.onChanged?.call(_items, _totalGeneral);
  }

  Future<void> _mostrarDialogoAgregar() async {
    final nombreCtrl = TextEditingController();
    final cantidadCtrl = TextEditingController();
    final precioCtrl = TextEditingController();

    final result = await showDialog<OrdenItem>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar ítem'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(labelText: 'Nombre del ítem'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: cantidadCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Cantidad'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: precioCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Precio unitario (Bs.)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final nombre = nombreCtrl.text.trim();
              final cantidad = int.tryParse(cantidadCtrl.text) ?? 0;
              final precio = double.tryParse(precioCtrl.text) ?? 0;
              if (nombre.isEmpty || cantidad <= 0 || precio <= 0) return;
              Navigator.pop(
                context,
                OrdenItem(
                  nombre: nombre,
                  cantidad: cantidad,
                  precioUnitario: precio,
                ),
              );
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );

    if (result != null) {
      _agregarItem(result);
    }
  }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ítems de la orden', style: AppTypography.h3),
              TextButton.icon(
                onPressed: _mostrarDialogoAgregar,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Agregar ítem'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(
                child: Text(
                  'No hay ítems. Agregá uno con el botón de arriba.',
                  style: AppTypography.small.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            )
          else
            // Header de la tabla
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'ÍTEM',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'CANT.',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'PRECIO',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'SUBTOTAL',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

          for (var i = 0; i < _items.length; i++)
            _ItemRow(item: _items[i], onDelete: () => _eliminarItem(i)),

          if (_items.isNotEmpty) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Bs. ${_totalGeneral.toStringAsFixed(2)}',
                    style: AppTypography.h3.copyWith(
                      color: AppColors.primary500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final OrdenItem item;
  final VoidCallback onDelete;

  const _ItemRow({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(item.nombre, style: AppTypography.small),
          ),
          Expanded(child: Text('${item.cantidad}', style: AppTypography.small)),
          Expanded(
            flex: 2,
            child: Text(
              'Bs. ${item.precioUnitario.toStringAsFixed(2)}',
              style: AppTypography.small,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Bs. ${item.subtotal.toStringAsFixed(2)}',
              style: AppTypography.small.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.close, size: 16),
              color: AppColors.textMuted,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }
}
