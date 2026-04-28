// ============================================================================
// orden_items_editor.dart
// Ubicación: lib/presentation/components/ordenes/orden_items_editor.dart
// Descripción: Editor reactivo de items de una orden. Permite agregar items
// reales (conectados a BD con dropdowns de tipo_prenda y talla) y ver el
// total actualizado. Cuando se agrega un ítem, se persiste en Supabase
// a través del provider.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/catalogos_provider.dart';

/// Item visual de una orden.
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
  /// Lista inicial de items (pre-cargada desde el modelo).
  final List<OrdenItem> initialItems;

  /// Callback que se dispara cuando cambia la lista de items.
  /// Útil para que el padre reciba el nuevo total.
  final void Function(List<OrdenItem> items, double nuevoTotal)? onChanged;

  /// Callback para persistir un nuevo ítem en Supabase.
  /// Recibe el mapa con id_tipo_prenda, id_talla, cantidad.
  /// Si es null, el editor funciona en modo solo-lectura (no muestra el botón agregar).
  final Future<void> Function(Map<String, dynamic> nuevoItem)? onAgregarItem;
  

  const OrdenItemsEditor({
    super.key,
    this.initialItems = const [],
    this.onChanged,
    this.onAgregarItem,
  });

  @override
  State<OrdenItemsEditor> createState() => _OrdenItemsEditorState();
}

class _OrdenItemsEditorState extends State<OrdenItemsEditor> {
  late List<OrdenItem> _items;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.initialItems);
  }

  double get _totalGeneral =>
      _items.fold(0, (sum, item) => sum + item.subtotal);

  void _agregarItemLocal(OrdenItem item) {
    setState(() => _items.add(item));
    widget.onChanged?.call(_items, _totalGeneral);
  }

  Future<void> _mostrarDialogoAgregar() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _AgregarItemDetalleDialog(),
    );

    if (result != null && mounted) {
      // 1. Agregar visualmente de inmediato
      final itemVisual = OrdenItem(
        nombre: '${result['nombre_prenda']} - Talla ${result['nombre_talla']}',
        cantidad: result['cantidad'] as int,
        precioUnitario: 0.0, // El precio real se recalcula en el service
      );
      _agregarItemLocal(itemVisual);

      // 2. Persistir en BD si el callback está conectado
      if (widget.onAgregarItem != null) {
        setState(() => _guardando = true);
        try {
          await widget.onAgregarItem!({
            'id_tipo_prenda': result['id_tipo_prenda'],
            'id_talla': result['id_talla'],
            'cantidad': result['cantidad'],
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ítem agregado y guardado en la orden'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al guardar: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _guardando = false);
        }
      }
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
              if (widget.onAgregarItem != null)
                _guardando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton.icon(
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
                  'No hay ítems registrados para esta orden.',
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
                    flex: 4,
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
                      'SUBTOTAL',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          for (var i = 0; i < _items.length; i++)
            _ItemRow(item: _items[i]),

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

  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(item.nombre, style: AppTypography.small),
          ),
          Expanded(
            child: Text('${item.cantidad}', style: AppTypography.small),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Bs. ${item.subtotal.toStringAsFixed(2)}',
              style: AppTypography.small.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DIALOG: Agregar ítem (CONECTADO A BD — mismo patrón que orden_productos_card)
// ═════════════════════════════════════════════════════════════════════════════
class _AgregarItemDetalleDialog extends ConsumerStatefulWidget {
  const _AgregarItemDetalleDialog();

  @override
  ConsumerState<_AgregarItemDetalleDialog> createState() =>
      _AgregarItemDetalleDialogState();
}

class _AgregarItemDetalleDialogState
    extends ConsumerState<_AgregarItemDetalleDialog> {
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

    Navigator.pop(context, {
      'id_tipo_prenda': _idPrenda,
      'id_talla': _idTalla,
      'cantidad': cantidad,
      'nombre_prenda': _nombrePrenda,
      'nombre_talla': _nombreTalla,
    });
  }

  @override
  Widget build(BuildContext context) {
    final prendasAsync = ref.watch(tiposPrendaProvider);
    final tallasAsync = ref.watch(tallasProvider);

    return AlertDialog(
      title: Text('Agregar ítem a la orden', style: AppTypography.h3),
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
