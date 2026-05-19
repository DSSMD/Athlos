// ============================================================================
// lib/presentation/pages/admin/plantillas/widgets/plantilla_form_paso3_materiales.dart
// ============================================================================
// Paso 3 del form multi-paso de Plantillas — Receta de Materiales.
// Lista dinámica de materiales: cada fila tiene dropdown de insumo,
// cantidad, label de unidad heredado del insumo, y papelera.
// - Los insumos se cargan del `insumosProvider` (solo activos, ordenados).
// - No se permiten insumos duplicados: los ya seleccionados aparecen
//   deshabilitados en los dropdowns de las demás filas.
// - Soporta layout responsive: filas horizontales en desktop, apiladas
//   en mobile (<600).
//
// DECISIÓN: permitir avanzar al Paso 4 con la lista vacía (0 materiales).
// RAZÓN: Den puede crear una plantilla sin receta y completarla luego
// editándola (consistente con Paso 2). La validación de "completar todos"
// vive en el padre (plantilla_form_page.dart _onSiguiente).
// CAMBIAR: si quieren obligar al menos 1 material, agregar validación en
// el padre antes de avanzar.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/models/inventario_model.dart';
import '../../../../../domain/models/material_plantilla_model.dart';


import '../../../../providers/plantilla_form_provider.dart';
import '../../../../providers/insumo_provider.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';

class PlantillaFormPaso3Materiales extends ConsumerWidget {
  const PlantillaFormPaso3Materiales({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(plantillaFormStateProvider);
    final notifier = ref.read(plantillaFormStateProvider.notifier);
    final insumosAsync = ref.watch(inventarioProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return insumosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'Error al cargar insumos: $e',
            style: AppTypography.small.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (insumos) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Receta de materiales', style: AppTypography.h3),
              const SizedBox(height: 2),
              Text(
                'Agregá los insumos necesarios para fabricar esta prenda.',
                style: AppTypography.small.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              if (state.materiales.isEmpty)
                const _EmptyMateriales()
              else ...[
                Column(
                  children: [
                    for (var i = 0; i < state.materiales.length; i++) ...[
                      _MaterialRow(
                        key: ValueKey('mat-${state.materiales[i].id}'),
                        material: state.materiales[i],
                        insumos: insumos,
                        seleccionadosOtros: _idsOcupadosPor(
                          state.materiales,
                          state.materiales[i].id,
                        ),
                        isMobile: isMobile,
                        onChangeInsumo: (id) =>
                            notifier.setMaterialInsumo(
                              state.materiales[i].id,
                              id,
                            ),
                        onChangeCantidad: (c) => notifier.setMaterialCantidad(
                          state.materiales[i].id,
                          c,
                        ),
                        onRemove: () =>
                            notifier.removerMaterial(state.materiales[i].id),
                      ),
                      if (i < state.materiales.length - 1)
                        const Divider(height: AppSpacing.md),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _FooterCostoTotal(materiales: state.materiales, insumos: insumos),
              ],
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: notifier.agregarMaterial,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Agregar insumo'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Devuelve los ids de insumos ocupados por OTROS materiales (excluye el
  /// material identificado por [idMaterialActual]). Se usa para deshabilitar
  /// esos ids en el dropdown del material actual.
  Set<String> _idsOcupadosPor(
    List<MaterialPlantilla> todos,
    String idMaterialActual,
  ) {
    return {
      for (final m in todos)
        if (m.id != idMaterialActual && m.idInsumo.isNotEmpty) m.idInsumo,
    };
  }
}

// ─── FILA DE MATERIAL ───────────────────────────────────────────────────────

class _MaterialRow extends StatefulWidget {
  const _MaterialRow({
    super.key,
    required this.material,
    required this.insumos,
    required this.seleccionadosOtros,
    required this.isMobile,
    required this.onChangeInsumo,
    required this.onChangeCantidad,
    required this.onRemove,
  });

  final MaterialPlantilla material;
  final List<InventarioItemModel> insumos;
  final Set<String> seleccionadosOtros;
  final bool isMobile;
  final ValueChanged<String> onChangeInsumo;
  final ValueChanged<double> onChangeCantidad;
  final VoidCallback onRemove;

  @override
  State<_MaterialRow> createState() => _MaterialRowState();
}

class _MaterialRowState extends State<_MaterialRow> {
  late final TextEditingController _cantidadCtrl;

  @override
  void initState() {
    super.initState();
    _cantidadCtrl = TextEditingController(
      text: widget.material.cantidad > 0
          ? _formatCantidad(widget.material.cantidad)
          : '',
    );
  }

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    super.dispose();
  }

  String _formatCantidad(double n) {
    if (n == n.truncateToDouble()) return n.toInt().toString();
    return n.toString();
  }

  String? _validarCantidad(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Ingresá una cantidad';
    final parsed = double.tryParse(raw);
    if (parsed == null) return 'Número inválido';
    if (parsed <= 0) return 'Mayor a 0';
    return null;
  }

  /// El value que mostramos al dropdown: el id actual del material si está
  /// en el catálogo, null si todavía no se eligió o no se encuentra.
  String? _valorActualDropdown() {
    if (widget.material.idInsumo.isEmpty) return null;
    final existe = widget.insumos.any(
      (i) => i.id == widget.material.idInsumo,
    );
    return existe ? widget.material.idInsumo : null;
  }

  /// Texto bajo el dropdown: unidad del insumo seleccionado, o '—'.
  String _unidadActual() {
    if (widget.material.idInsumo.isEmpty) return '—';
    final insumo = widget.insumos
        .where((i) => i.id == widget.material.idInsumo)
        .firstOrNull;
    final unidad = insumo?.unidad ?? '';
    return unidad.isEmpty ? '—' : unidad;
  }

  @override
  Widget build(BuildContext context) {
    // DropdownMenu (Material 3) con búsqueda built-in. Reemplazó al
    // DropdownButtonFormField anterior para cumplir con el spec del PDF
    // de Den: "Dropdown ▼ + Buscar (Q)". `enableFilter + enableSearch`
    // filtra la lista por substring del label mientras el usuario tipea.
    // `expandedInsets: EdgeInsets.zero` hace que el campo ocupe todo el
    // ancho del parent (Expanded en desktop, full width en mobile).
    final dropdown = DropdownMenu<String>(
      initialSelection: _valorActualDropdown(),
      label: const Text('Insumo *'),
      hintText: 'Buscar insumo...',
      enableFilter: true,
      enableSearch: true,
      requestFocusOnTap: true,
      menuHeight: 320,
      expandedInsets: EdgeInsets.zero,
      dropdownMenuEntries: widget.insumos
          .where((i) => i.activo || i.id == widget.material.idInsumo)
          .map((i) {
        final yaUsadoEnOtraFila = widget.seleccionadosOtros.contains(i.id);
        final base =
            '${i.nombre}${i.unidad.isNotEmpty ? ' (${i.unidad})' : ''}';
        final label = !i.activo
            ? '$base (Desactivado)'
            : (yaUsadoEnOtraFila ? '$base — ya seleccionado' : base);
        return DropdownMenuEntry<String>(
          value: i.id,
          label: label,
          enabled: i.activo && !yaUsadoEnOtraFila,
        );
      }).toList(),
      onSelected: (v) {
        if (v != null) widget.onChangeInsumo(v);
      },
    );

    final cantidad = TextFormField(
      controller: _cantidadCtrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: 'Cantidad *',
        border: const OutlineInputBorder(),
        isDense: true,
        suffixText: _unidadActual() == '—' ? null : _unidadActual(),
      ),
      validator: _validarCantidad,
      onChanged: (v) {
        final parsed = double.tryParse(v) ?? 0;
        widget.onChangeCantidad(parsed);
      },
    );

    final insumoSelected = widget.insumos.where((i) => i.id == widget.material.idInsumo).firstOrNull;
    final costoUnitario = insumoSelected?.costoUnitario ?? 0.0;
    final costoParcial = widget.material.cantidad * costoUnitario;
    
    final costoText = Text(
      '${costoParcial.toStringAsFixed(2)} Bs.',
      style: AppTypography.small.copyWith(
        color: AppColors.success,
        fontWeight: FontWeight.w600,
      ),
    );

    final papelera = IconButton(
      icon: const Icon(Icons.delete_outline, size: 20),
      color: AppColors.error,
      tooltip: 'Eliminar material',
      onPressed: widget.onRemove,
    );

    if (widget.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          dropdown,
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(child: cantidad),
              const SizedBox(width: AppSpacing.sm),
              costoText,
              const SizedBox(width: AppSpacing.xs),
              papelera,
            ],
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(flex: 5, child: dropdown),
          const SizedBox(width: AppSpacing.sm),
          Expanded(flex: 2, child: cantidad),
          const SizedBox(width: AppSpacing.md),
          SizedBox(width: 80, child: costoText),
          papelera,
        ],
      ),
    );
  }
}

// ─── EMPTY STATE ────────────────────────────────────────────────────────────

class _EmptyMateriales extends StatelessWidget {
  const _EmptyMateriales();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 32,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            "Aún no agregaste materiales.",
            style: AppTypography.small.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "Apretá '+ Agregar insumo' para empezar la receta.",
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── FOOTER COSTO TOTAL ──────────────────────────────────────────────────────

class _FooterCostoTotal extends StatelessWidget {
  const _FooterCostoTotal({
    required this.materiales,
    required this.insumos,
  });

  final List<MaterialPlantilla> materiales;
  final List<InventarioItemModel> insumos;

  @override
  Widget build(BuildContext context) {
    double total = 0.0;
    for (final m in materiales) {
      final insumo = insumos.where((i) => i.id == m.idInsumo).firstOrNull;
      if (insumo != null) {
        total += m.cantidad * insumo.costoUnitario;
      }
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Costo Total Estimado',
            style: AppTypography.small.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '${total.toStringAsFixed(2)} Bs.',
            style: AppTypography.h3.copyWith(
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}
