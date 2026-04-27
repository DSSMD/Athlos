// ============================================================================
// orden_info_card.dart
// Ubicación: lib/presentation/components/ordenes/orden_info_card.dart
// Descripción: Card "Información del pedido" del form Crear Orden (SCRUM-75).
// Contiene: selector de cliente, fecha de entrega, producto rápido,
// toggle de moneda Bs/USD, banner tipo de cambio, descripción.
//
// El header del Figma duplica producto/cantidad/precio que también aparecen
// en la tabla "Productos de la orden". Mantenemos esa duplicación tal como
// está en el diseño (decisión documentada).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/custom_text_field.dart';

import 'orden_draft.dart';

class OrdenInfoCard extends StatefulWidget {
  final OrdenDraft draft;
  final ValueChanged<OrdenDraft> onChanged;

  const OrdenInfoCard({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  @override
  State<OrdenInfoCard> createState() => _OrdenInfoCardState();
}

class _OrdenInfoCardState extends State<OrdenInfoCard> {
  // ═══════════════════════════════════════════════════════════════════════════
  // MOCK DATA — se reemplaza cuando Mel exponga los providers
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<Map<String, String>> _clientesMock = [
    {'id': 'cli-001', 'nombre': 'Empresa Textil S.A.'},
    {'id': 'cli-002', 'nombre': 'Confecciones del Sur'},
    {'id': 'cli-003', 'nombre': 'María López'},
    {'id': 'cli-004', 'nombre': 'Carlos Ruiz'},
    {'id': 'cli-005', 'nombre': 'Ana Torres'},
  ];

  static const List<String> _unidadesMock = [
    'Unidades',
    'Metros',
    'Kilogramos',
    'Cajas',
    'Pares',
  ];

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTROLLERS — necesarios porque CustomTextField requiere `controller`,
  // no acepta `initialValue`. Se inicializan con el valor del draft.
  // ═══════════════════════════════════════════════════════════════════════════
  late final TextEditingController _productoCtrl;
  late final TextEditingController _cantidadCtrl;
  late final TextEditingController _precioCtrl;
  late final TextEditingController _descripcionCtrl;

  @override
  void initState() {
    super.initState();
    _productoCtrl = TextEditingController(
      text: widget.draft.productoRapidoNombre,
    );
    _cantidadCtrl = TextEditingController(
      text: widget.draft.productoRapidoCantidad == 0
          ? ''
          : '${widget.draft.productoRapidoCantidad}',
    );
    _precioCtrl = TextEditingController(
      text: widget.draft.productoRapidoPrecio == 0
          ? ''
          : widget.draft.productoRapidoPrecio.toStringAsFixed(2),
    );
    _descripcionCtrl = TextEditingController(text: widget.draft.descripcion);
  }

  @override
  void dispose() {
    _productoCtrl.dispose();
    _cantidadCtrl.dispose();
    _precioCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS — actualización del draft
  // ═══════════════════════════════════════════════════════════════════════════
  void _setCliente(String? id) {
    widget.onChanged(widget.draft.copyWith(idCliente: id));
  }

  Future<void> _pickFecha() async {
    final hoy = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate:
          widget.draft.fechaEntrega ?? hoy.add(const Duration(days: 7)),
      firstDate: hoy,
      lastDate: hoy.add(const Duration(days: 365)),
    );
    if (picked != null) {
      widget.onChanged(widget.draft.copyWith(fechaEntrega: picked));
    }
  }

  void _setMoneda(OrdenMoneda m) {
    widget.onChanged(widget.draft.copyWith(moneda: m));
  }

  String _fechaDisplay() {
    final f = widget.draft.fechaEntrega;
    if (f == null) return 'dd/mm/yyyy';
    return '${f.day.toString().padLeft(2, '0')}/'
        '${f.month.toString().padLeft(2, '0')}/'
        '${f.year}';
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          const SizedBox(height: AppSpacing.lg),
          _filaClienteFecha(),
          const SizedBox(height: AppSpacing.lg),
          _filaProductoCantidad(),
          const SizedBox(height: AppSpacing.lg),
          _toggleMoneda(),
          const SizedBox(height: AppSpacing.lg),
          _filaPrecioUnidad(),
          const SizedBox(height: AppSpacing.lg),
          _bannerTipoCambio(),
          if (widget.draft.moneda == OrdenMoneda.dolares)
            const SizedBox(height: AppSpacing.lg),
          _descripcion(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _header() {
    return Row(
      children: [
        Text('Información del pedido', style: AppTypography.h3),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.info.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            'Actualizado',
            style: AppTypography.caption.copyWith(
              color: AppColors.info,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILA: Cliente + Fecha
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _filaClienteFecha() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _selectorCliente()),
        const SizedBox(width: AppSpacing.lg),
        Expanded(child: _selectorFecha()),
      ],
    );
  }

  Widget _selectorCliente() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Cliente *'),
        const SizedBox(height: AppSpacing.xs),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: widget.draft.idCliente,
              isExpanded: true,
              hint: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'Seleccionar o buscar cliente...',
                  style: AppTypography.small.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              items: _clientesMock
                  .map(
                    (c) => DropdownMenuItem(
                      value: c['id'],
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: Text(c['nombre']!),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _setCliente,
            ),
          ),
        ),
      ],
    );
  }

  Widget _selectorFecha() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Fecha de entrega *'),
        const SizedBox(height: AppSpacing.xs),
        InkWell(
          onTap: _pickFecha,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _fechaDisplay(),
                    style: AppTypography.small.copyWith(
                      color: widget.draft.fechaEntrega == null
                          ? AppColors.textMuted
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILA: Producto + Cantidad
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _filaProductoCantidad() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: CustomTextField(
            label: 'Producto *',
            hint: 'Ej: Camisas polo manga corta',
            controller: _productoCtrl,
            onChanged: (v) => widget.onChanged(
              widget.draft.copyWith(productoRapidoNombre: v),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          flex: 1,
          child: CustomTextField(
            label: 'Cantidad *',
            hint: '0',
            controller: _cantidadCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (v) {
              final n = int.tryParse(v) ?? 0;
              widget.onChanged(
                widget.draft.copyWith(productoRapidoCantidad: n),
              );
            },
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TOGGLE MONEDA
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _toggleMoneda() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _label('Moneda de la orden'),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                'Nuevo',
                style: AppTypography.caption.copyWith(
                  color: AppColors.info,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Expanded(
                child: _monedaOption(
                  label: 'Bs — Bolivianos',
                  selected: widget.draft.moneda == OrdenMoneda.bolivianos,
                  onTap: () => _setMoneda(OrdenMoneda.bolivianos),
                ),
              ),
              Expanded(
                child: _monedaOption(
                  label: '\$ — Dólares (USD)',
                  selected: widget.draft.moneda == OrdenMoneda.dolares,
                  onTap: () => _setMoneda(OrdenMoneda.dolares),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _monedaOption({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary500 : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: AppTypography.small.copyWith(
            color: selected ? AppColors.brandWhite : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FILA: Precio + Unidad
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _filaPrecioUnidad() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Precio unitario'),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.neutral100,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      widget.draft.moneda == OrdenMoneda.dolares
                          ? 'USD \$'
                          : 'Bs',
                      style: AppTypography.small.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: CustomTextField(
                      label: '',
                      hint: '0.00',
                      controller: _precioCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}'),
                        ),
                      ],
                      onChanged: (v) {
                        final n = double.tryParse(v) ?? 0;
                        widget.onChanged(
                          widget.draft.copyWith(productoRapidoPrecio: n),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label('Unidad de medida'),
              const SizedBox(height: AppSpacing.xs),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: widget.draft.productoRapidoUnidad,
                    isExpanded: true,
                    items: _unidadesMock
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
                      if (v != null) {
                        widget.onChanged(
                          widget.draft.copyWith(productoRapidoUnidad: v),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BANNER TIPO DE CAMBIO (solo si moneda = USD)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _bannerTipoCambio() {
    if (widget.draft.moneda != OrdenMoneda.dolares) {
      return const SizedBox.shrink();
    }

    final totalUsd =
        widget.draft.productoRapidoCantidad * widget.draft.productoRapidoPrecio;
    final totalBs = totalUsd * kTipoCambioUsdBs;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.info),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AppTypography.small,
                children: [
                  const TextSpan(
                    text: 'Tipo de cambio:  ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text:
                        '1 USD = ${kTipoCambioUsdBs.toStringAsFixed(2)} Bs '
                        '— Total equivalente: '
                        'Bs ${totalBs.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DESCRIPCIÓN
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _descripcion() {
    // CustomTextField no soporta maxLines, usamos TextField directo aquí
    // para el campo multilinea de descripción.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Descripción / especificaciones'),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _descripcionCtrl,
          maxLines: 4,
          onChanged: (v) =>
              widget.onChanged(widget.draft.copyWith(descripcion: v)),
          decoration: InputDecoration(
            hintText: 'Detalles del producto, materiales, tallas, colores...',
            hintStyle: AppTypography.small.copyWith(color: AppColors.textMuted),
            contentPadding: const EdgeInsets.all(AppSpacing.md),
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
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER: label
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _label(String text) {
    return Text(
      text,
      style: AppTypography.small.copyWith(
        color: AppColors.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
