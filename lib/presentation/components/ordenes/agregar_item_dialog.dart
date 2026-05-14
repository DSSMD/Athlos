import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/detalle_orden_model.dart';
import '../../providers/catalogos_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import 'orden_draft.dart';

/// Diálogo unificado para agregar un ítem (conjunto o plantilla) a una orden.
/// Reemplaza a los dialogs legacy _AgregarProductoDialog y
/// _AgregarItemDetalleDialog que solo soportaban tipo_prenda + 1 talla.
///
/// Comportamiento:
/// - Selector tipo: Conjunto vs Plantilla suelta
/// - Dropdown del ítem (según tipo)
/// - Input de precio unitario manual (lo "pone al dedo" el vendedor,
///   confirmado por el stakeholder — el precio no viene del catálogo)
/// - Lista dinámica de tallas con cantidad por cada una
/// - Subtotal calculado en vivo (precio × suma de cantidades)
/// - Devuelve OrdenItemDraft al confirmar
class AgregarItemDialog extends ConsumerStatefulWidget {
  const AgregarItemDialog({super.key});

  @override
  ConsumerState<AgregarItemDialog> createState() => _AgregarItemDialogState();
}

class _AgregarItemDialogState extends ConsumerState<AgregarItemDialog> {
  // ─── Estado ───
  TipoItem _tipoItem = TipoItem.conjunto;
  String? _idItemSel; // ID del conjunto o plantilla seleccionada
  String _nombreItemSel = ''; // nombre denormalizado para el OrdenItemDraft

  final _precioCtrl = TextEditingController();
  final List<_TallaRow> _tallaRows = [_TallaRow()];

  @override
  void dispose() {
    _precioCtrl.dispose();
    for (final r in _tallaRows) {
      r.cantidadCtrl.dispose();
    }
    super.dispose();
  }

  double get _precioUnitario => double.tryParse(_precioCtrl.text) ?? 0.0;
  int get _cantidadTotal => _tallaRows.fold(0, (sum, r) => sum + r.cantidad);
  double get _subtotal => _precioUnitario * _cantidadTotal;

  bool get _esValido {
    if (_idItemSel == null) return false;
    if (_precioUnitario <= 0) return false;
    if (_cantidadTotal <= 0) return false;
    for (final r in _tallaRows) {
      if (r.idTalla == null || r.cantidad <= 0) return false;
    }
    return true;
  }

  void _onTipoChanged(TipoItem nuevo) {
    setState(() {
      _tipoItem = nuevo;
      _idItemSel = null;
      _nombreItemSel = '';
    });
  }

  void _agregarTallaRow() {
    setState(() => _tallaRows.add(_TallaRow()));
  }

  void _quitarTallaRow(int index) {
    if (_tallaRows.length <= 1) return;
    setState(() {
      _tallaRows[index].cantidadCtrl.dispose();
      _tallaRows.removeAt(index);
    });
  }

  void _guardar() {
    if (!_esValido) return;

    final tallas = _tallaRows
        .map(
          (r) => OrdenTallaDraft(
            idTalla: r.idTalla!,
            nombreTalla: r.nombreTalla ?? '',
            cantidad: r.cantidad,
          ),
        )
        .toList();

    final item = OrdenItemDraft(
      tipoItem: _tipoItem,
      idConjunto: _tipoItem == TipoItem.conjunto ? _idItemSel : null,
      idPlantilla: _tipoItem == TipoItem.plantilla ? _idItemSel : null,
      nombre: _nombreItemSel,
      precioUnitario: _precioUnitario,
      tallas: tallas,
    );

    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Agregar ítem a la orden', style: AppTypography.h3),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Tipo de ítem'),
              const SizedBox(height: AppSpacing.xs),
              _tipoSelector(),
              const SizedBox(height: AppSpacing.md),

              _label(_tipoItem == TipoItem.conjunto ? 'Conjunto' : 'Plantilla'),
              const SizedBox(height: AppSpacing.xs),
              _itemDropdown(),
              const SizedBox(height: AppSpacing.md),

              _label('Precio unitario (Bs.) *'),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                controller: _precioCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                onChanged: (_) => setState(() {}),
                decoration: _decoration('0.00'),
              ),
              const SizedBox(height: AppSpacing.md),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _label('Tallas y cantidades *'),
                  TextButton.icon(
                    onPressed: _agregarTallaRow,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Agregar talla'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              ..._tallaRows.asMap().entries.map(
                (entry) => _tallaRowWidget(entry.key, entry.value),
              ),
              const SizedBox(height: AppSpacing.md),

              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.neutral50,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal ($_cantidadTotal × Bs. ${_precioUnitario.toStringAsFixed(2)})',
                      style: AppTypography.small.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Bs. ${_subtotal.toStringAsFixed(2)}',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _esValido ? _guardar : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary500,
            foregroundColor: Colors.white,
          ),
          child: const Text('Agregar'),
        ),
      ],
    );
  }

  Widget _tipoSelector() {
    return SegmentedButton<TipoItem>(
      segments: const [
        ButtonSegment(
          value: TipoItem.conjunto,
          label: Text('Conjunto'),
          icon: Icon(Icons.inventory_2_outlined, size: 16),
        ),
        ButtonSegment(
          value: TipoItem.plantilla,
          label: Text('Plantilla suelta'),
          icon: Icon(Icons.checkroom, size: 16),
        ),
      ],
      selected: {_tipoItem},
      onSelectionChanged: (Set<TipoItem> selected) {
        _onTipoChanged(selected.first);
      },
    );
  }

  Widget _itemDropdown() {
    if (_tipoItem == TipoItem.conjunto) {
      final asyncConjuntos = ref.watch(conjuntosProvider);
      return asyncConjuntos.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e', style: AppTypography.small),
        data: (conjuntos) {
          if (conjuntos.isEmpty) {
            return Text(
              'No hay conjuntos activos en el catálogo',
              style: AppTypography.small.copyWith(color: AppColors.textMuted),
            );
          }
          return DropdownButtonFormField<String>(
            initialValue: _idItemSel,
            decoration: _decoration('Selecciona un conjunto'),
            items: conjuntos
                .map(
                  (c) => DropdownMenuItem<String>(
                    value: c.idConjunto,
                    child: Text(c.nombre),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val == null) return;
              setState(() {
                _idItemSel = val;
                _nombreItemSel = conjuntos
                    .firstWhere((c) => c.idConjunto == val)
                    .nombre;
              });
            },
          );
        },
      );
    } else {
      final asyncPlantillas = ref.watch(plantillasProvider);
      return asyncPlantillas.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Error: $e', style: AppTypography.small),
        data: (plantillas) {
          if (plantillas.isEmpty) {
            return Text(
              'No hay plantillas activas en el catálogo',
              style: AppTypography.small.copyWith(color: AppColors.textMuted),
            );
          }
          return DropdownButtonFormField<String>(
            initialValue: _idItemSel,
            decoration: _decoration('Selecciona una plantilla'),
            items: plantillas
                .map(
                  (p) => DropdownMenuItem<String>(
                    value: p.idPlantilla,
                    child: Text(
                      p.nombreTipoPrenda != null
                          ? '${p.nombre} (${p.nombreTipoPrenda})'
                          : p.nombre,
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val == null) return;
              setState(() {
                _idItemSel = val;
                _nombreItemSel = plantillas
                    .firstWhere((p) => p.idPlantilla == val)
                    .nombre;
              });
            },
          );
        },
      );
    }
  }

  Widget _tallaRowWidget(int index, _TallaRow row) {
    final tallasAsync = ref.watch(tallasProvider);
    final isOnlyRow = _tallaRows.length == 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: tallasAsync.when(
              loading: () => const SizedBox(
                height: 40,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => const Text('Error'),
              data: (tallas) => DropdownButtonFormField<int>(
                initialValue: row.idTalla,
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
                  if (val == null) return;
                  setState(() {
                    row.idTalla = val;
                    row.nombreTalla =
                        tallas.firstWhere(
                              (t) => t['id_talla'] == val,
                            )['nombre_talla']
                            as String;
                  });
                },
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: TextField(
              controller: row.cantidadCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (val) {
                setState(() => row.cantidad = int.tryParse(val) ?? 0);
              },
              decoration: _decoration('0'),
            ),
          ),
          IconButton(
            onPressed: isOnlyRow ? null : () => _quitarTallaRow(index),
            icon: const Icon(Icons.close, size: 18),
            tooltip: isOnlyRow ? 'Mínimo una talla' : 'Quitar talla',
          ),
        ],
      ),
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

/// Estructura interna mutable para cada fila de talla en el form del dialog.
class _TallaRow {
  int? idTalla;
  String? nombreTalla;
  int cantidad = 0;
  final TextEditingController cantidadCtrl = TextEditingController();
}
