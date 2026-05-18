// lib/presentation/components/ordenes/agregar_item_dialog.dart

// Diálogo para agregar un ítem (conjunto o plantilla suelta) a la orden en creación.
// Permite seleccionar el tipo de ítem, elegir el conjunto/plantilla del catálogo,
// y luego configurar tallas, cantidades y precios unitarios antes de agregarlo al draft
// de la orden. El resultado es una lista de OrdenItemDraft que se devuelve al form para su inclusión


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/models/detalle_orden_model.dart';
import '../../providers/catalogos_provider.dart';
import '../../../data/services/conjunto_service.dart';
import '../../../data/services/plantilla_service.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import 'orden_draft.dart';

class AgregarItemDialog extends ConsumerStatefulWidget {
  const AgregarItemDialog({super.key});

  @override
  ConsumerState<AgregarItemDialog> createState() => _AgregarItemDialogState();
}

class _AgregarItemDialogState extends ConsumerState<AgregarItemDialog> {
  // ─── Estado ───
  TipoItem _tipoItem = TipoItem.conjunto;
  String? _idItemGeneralSel;
  String _nombreItemGeneralSel = '';
  bool _cargandoDatos = false;

  // Lista dinámica de secciones (Una por plantilla)
  final List<_ItemSectionState> _secciones = [];

  @override
  void dispose() {
    for (final s in _secciones) {
      s.dispose();
    }
    super.dispose();
  }

  // ─── Cálculos Globales ───
  int get _cantidadTotalGeneral =>
      _secciones.fold(0, (sum, s) => sum + s.cantidadTotal);
  double get _subtotalGeneral =>
      _secciones.fold(0.0, (sum, s) => sum + s.subtotal);

  bool get _esValido {
    if (_secciones.isEmpty) return false;
    bool tieneAlMenosUnItem = false;

    for (final s in _secciones) {
      if (s.cantidadTotal > 0) {
        if (s.precioUnitario <= 0) return false;
        for (final r in s.tallaRows) {
          if (r.idTalla == null && r.cantidad > 0) return false;
        }
        tieneAlMenosUnItem = true;
      }
    }
    return tieneAlMenosUnItem;
  }

  void _onTipoChanged(TipoItem nuevo) {
    setState(() {
      _tipoItem = nuevo;
      _idItemGeneralSel = null;
      _nombreItemGeneralSel = '';
      for (final s in _secciones) {
        s.dispose();
      }
      _secciones.clear();
    });
  }

  Future<void> _cargarDatosItem(String id) async {
    setState(() {
      _cargandoDatos = true;
      for (final s in _secciones) {
        s.dispose();
      }
      _secciones.clear();
    });

    try {
      // Intentamos recuperar la lista de tallas del Provider
      final tallasList = ref
          .read(tallasProvider)
          .maybeWhen(data: (data) => data, orElse: () => []);

      if (_tipoItem == TipoItem.conjunto) {
        final conjunto = await ConjuntoService().obtenerConjuntoCompleto(id);

        final futures = conjunto.plantillas.map(
          (cp) => PlantillaService().obtenerPlantillaCompleta(cp.plantillaId),
        );
        final plantillasCompletas = await Future.wait(futures);

        setState(() {
          for (final p in plantillasCompletas) {
            final seccion = _ItemSectionState(
              idPlantilla: p.id,
              nombrePlantilla: p.nombre,
              precioInicial: p.precioPlantilla,
            );

            if (p.tallasSeleccionadas.isNotEmpty) {
              seccion.tallaRows.clear();
              for (final tId in p.tallasSeleccionadas) {
                final r = _TallaRow()..idTalla = tId;

                // CORRECCIÓN: Búsqueda segura para evitar que la UI colapse (StateError)
                // si el catálogo de tallas está temporalmente vacío.
                try {
                  final tRef = tallasList.firstWhere((t) => t.id == tId);
                  r.nombreTalla = tRef.nombre;
                } catch (_) {
                  r.nombreTalla = 'Talla $tId'; // Fallback seguro
                }

                seccion.tallaRows.add(r);
              }
            }
            _secciones.add(seccion);
          }
        });
      } else {
        final plantilla = await PlantillaService().obtenerPlantillaCompleta(id);

        setState(() {
          final seccion = _ItemSectionState(
            idPlantilla: plantilla.id,
            nombrePlantilla: plantilla.nombre,
            precioInicial: plantilla.precioPlantilla,
          );

          if (plantilla.tallasSeleccionadas.isNotEmpty) {
            seccion.tallaRows.clear();
            for (final tId in plantilla.tallasSeleccionadas) {
              final r = _TallaRow()..idTalla = tId;

              // CORRECCIÓN: Búsqueda segura
              try {
                final tRef = tallasList.firstWhere((t) => t.id == tId);
                r.nombreTalla = tRef.nombre;
              } catch (_) {
                r.nombreTalla = 'Talla $tId'; // Fallback seguro
              }

              seccion.tallaRows.add(r);
            }
          }
          _secciones.add(seccion);
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Error cargando detalles del item: $e');
      debugPrint('Stacktrace: $stackTrace');

      // MOSTRAR EL ERROR EN PANTALLA
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
            backgroundColor: Colors.red.shade800,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _cargandoDatos = false);
    }
  }

  void _guardar() {
    if (!_esValido) return;

    final List<OrdenItemDraft> itemsGenerados = [];

    for (final seccion in _secciones) {
      if (seccion.cantidadTotal == 0)
        continue; // Ignoramos si no se pidieron piezas de esta plantilla

      final tallas = seccion.tallaRows
          .where((r) => r.cantidad > 0 && r.idTalla != null)
          .map(
            (r) => OrdenTallaDraft(
              idTalla: r.idTalla!,
              nombreTalla: r.nombreTalla ?? '',
              cantidad: r.cantidad,
            ),
          )
          .toList();

      // Añadimos el sufijo para que visualmente se sepa de qué conjunto viene
      final nombreFinal = _tipoItem == TipoItem.conjunto
          ? '${seccion.nombrePlantilla} (De: $_nombreItemGeneralSel)'
          : seccion.nombrePlantilla;

      final item = OrdenItemDraft(
        tipoItem: TipoItem
            .plantilla, // Siempre guardamos como plantilla suelta (Atajo)
        idConjunto: null,
        idPlantilla: seccion.idPlantilla,
        nombre: nombreFinal,
        precioUnitario: seccion.precioUnitario,
        tallas: tallas,
      );

      itemsGenerados.add(item);
    }

    Navigator.pop(context, itemsGenerados);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Agregar ítem a la orden', style: AppTypography.h3),
      content: SizedBox(
        width: 550,
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
              if (_cargandoDatos) const LinearProgressIndicator(),
              const SizedBox(height: AppSpacing.md),

              if (_secciones.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: AppSpacing.sm),
                ..._secciones.asMap().entries.map(
                  (e) => _buildSeccionPlantilla(e.key, e.value),
                ),
              ],

              if (_secciones.isNotEmpty) ...[
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
                        'Total General ($_cantidadTotalGeneral piezas)',
                        style: AppTypography.small.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'Bs. ${_subtotalGeneral.toStringAsFixed(2)}',
                        style: AppTypography.body.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

  Widget _buildSeccionPlantilla(int indexSeccion, _ItemSectionState seccion) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.checkroom, size: 20, color: AppColors.primary500),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  seccion.nombrePlantilla,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          _label('Precio unitario (Bs.) *'),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: seccion.precioCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                onPressed: () =>
                    setState(() => seccion.tallaRows.add(_TallaRow())),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Talla'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          ...seccion.tallaRows.asMap().entries.map(
            (entry) => _tallaRowWidget(seccion, entry.key, entry.value),
          ),
        ],
      ),
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
            initialValue: _idItemGeneralSel,
            decoration: _decoration('Selecciona un conjunto'),
            items: conjuntos
                .map(
                  (c) => DropdownMenuItem(value: c.id, child: Text(c.nombre)),
                )
                .toList(),
            onChanged: (val) {
              if (val == null) return;
              setState(() {
                _idItemGeneralSel = val;
                _nombreItemGeneralSel = conjuntos
                    .firstWhere((c) => c.id == val)
                    .nombre;
              });
              _cargarDatosItem(val);
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
            initialValue: _idItemGeneralSel,
            decoration: _decoration('Selecciona una plantilla'),
            items: plantillas
                .map(
                  (p) => DropdownMenuItem(
                    value: p.id,
                    child: Text(
                      '${p.nombre} (${p.nombreTipoPrendaJoin ?? 'Sin tipo'})',
                    ),
                  ),
                )
                .toList(),
            onChanged: (val) {
              if (val == null) return;
              setState(() {
                _idItemGeneralSel = val;
                _nombreItemGeneralSel = plantillas
                    .firstWhere((p) => p.id == val)
                    .nombre;
              });
              _cargarDatosItem(val);
            },
          );
        },
      );
    }
  }

  Widget _tallaRowWidget(_ItemSectionState seccion, int index, _TallaRow row) {
    final tallasAsync = ref.watch(tallasProvider);
    final isOnlyRow = seccion.tallaRows.length == 1;

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
                        value: t.id,
                        child: Text(t.nombre),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val == null) return;
                  setState(() {
                    row.idTalla = val;
                    row.nombreTalla = tallas
                        .firstWhere((t) => t.id == val)
                        .nombre;
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
            onPressed: isOnlyRow
                ? null
                : () => setState(() => seccion.tallaRows.removeAt(index)),
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

/// Estado interno para cada sección de plantilla
class _ItemSectionState {
  final String idPlantilla;
  final String nombrePlantilla;
  final TextEditingController precioCtrl;
  final List<_TallaRow> tallaRows;

  _ItemSectionState({
    required this.idPlantilla,
    required this.nombrePlantilla,
    required double precioInicial,
  }) : precioCtrl = TextEditingController(
         text: precioInicial.toStringAsFixed(2),
       ),
       tallaRows = [_TallaRow()];

  void dispose() {
    precioCtrl.dispose();
    for (final r in tallaRows) {
      r.cantidadCtrl.dispose();
    }
  }

  double get precioUnitario => double.tryParse(precioCtrl.text) ?? 0.0;
  int get cantidadTotal => tallaRows.fold(0, (sum, r) => sum + r.cantidad);
  double get subtotal => precioUnitario * cantidadTotal;
}

/// Estructura interna mutable para cada fila de talla en el form del dialog.
class _TallaRow {
  int? idTalla;
  String? nombreTalla;
  int cantidad = 0;
  final TextEditingController cantidadCtrl = TextEditingController();
}
