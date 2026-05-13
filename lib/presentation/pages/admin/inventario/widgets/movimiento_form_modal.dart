import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/models/inventario_model.dart';
import '../../../../../domain/models/movimiento_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/inventario_provider.dart';
import '../../../../providers/movimiento_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../../../theme/breakpoints.dart';
import 'compra_calculadora.dart';

/// Abre el modal para registrar un nuevo movimiento de stock.
///
/// Desktop: Dialog centrado (700×700). Mobile: fullscreen route.
void showMovimientoFormModal(BuildContext context) {
  if (context.isMobile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const MovimientoFormModal(isMobile: true),
      ),
    );
  } else {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const MovimientoFormModal(isMobile: false),
    );
  }
}

class MovimientoFormModal extends ConsumerStatefulWidget {
  const MovimientoFormModal({super.key, required this.isMobile});

  final bool isMobile;

  @override
  ConsumerState<MovimientoFormModal> createState() =>
      _MovimientoFormModalState();
}

class _MovimientoFormModalState extends ConsumerState<MovimientoFormModal> {
  final _formKey      = GlobalKey<FormState>();
  final _cantidadCtrl = TextEditingController(); // solo para SALIDA
  final _motivoCtrl   = TextEditingController();

  InventarioItemModel? _insumo;
  TipoMovimiento? _tipo;
  bool _saving = false;
  String? _insumoError;

  /// Resultado de la calculadora (solo para INGRESO)
  CompraResult _compraResult = CompraResult.empty;

  bool get _esIngreso => _tipo == TipoMovimiento.ingreso;

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _motivoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMobile) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              const Divider(height: 1, color: AppColors.border),
              Expanded(child: _buildForm()),
              const Divider(height: 1, color: AppColors.border),
              _buildActions(),
            ],
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            const Divider(height: 1, color: AppColors.border),
            Flexible(child: _buildForm()),
            const Divider(height: 1, color: AppColors.border),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Text('Registrar Movimiento', style: AppTypography.h2),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    final asyncInsumos = ref.watch(inventarioProvider);
    final insumos = asyncInsumos.value ?? const <InventarioItemModel>[];
    final nombreUnidad = _insumo?.unidad ?? 'unidad';
    // Si el insumo se mide en metros, asumimos que viene en rollos (es dimensionable)
    final esDim = _insumo != null &&
        (_insumo!.unidad.toLowerCase().contains('metro') ||
         _insumo!.unidad.toLowerCase() == 'm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _label('Insumo'),
            LayoutBuilder(
              builder: (context, constraints) {
                return DropdownMenu<InventarioItemModel>(
                  initialSelection: _insumo,
                  enabled: !_saving,
                  enableFilter: true,
                  enableSearch: true,
                  requestFocusOnTap: true,
                  width: constraints.maxWidth,
                  menuHeight: 300,
                  hintText: 'Buscar insumo...',
                  errorText: _insumoError,
                  dropdownMenuEntries: insumos
                      .map(
                        (i) => DropdownMenuEntry<InventarioItemModel>(
                          value: i,
                          label: '${i.codigo} — ${i.nombre}',
                        ),
                      )
                      .toList(),
                  onSelected: _saving
                      ? null
                      : (v) => setState(() {
                          _insumo = v;
                          _insumoError = null;
                          _compraResult = CompraResult.empty;
                          _motivoCtrl.clear();
                        }),
                );
              },
            ),
            if (_insumo != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Stock actual: ${_formatStock(_insumo!.stockActual)} ${_insumo!.unidad}  '
                '•  CPP: Bs ${_formatStock(_insumo!.costoUnitario)}/${_insumo!.unidad}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            _label('Tipo de movimiento'),
            DropdownButtonFormField<TipoMovimiento>(
              initialValue: _tipo,
              isExpanded: true,
              items: const [TipoMovimiento.ingreso, TipoMovimiento.salida]
                  .map((t) => DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: _saving
                  ? null
                  : (v) => setState(() {
                        _tipo = v;
                        _compraResult = CompraResult.empty;
                        _motivoCtrl.clear();
                      }),
              validator: (v) => v == null ? 'Seleccioná un tipo' : null,
            ),
            const SizedBox(height: AppSpacing.lg),

            // ── INGRESO: calculadora de compra ─────────────────────────────
            if (_esIngreso) ...[
              _label('¿Cómo compraste el material?'),
              CompraCalculadora(
                nombreUnidad: nombreUnidad,
                esDimensionable: esDim,
                enabled: !_saving && _insumo != null,
                onResultChanged: (result) {
                  setState(() {
                    _compraResult = result;
                    if (_motivoCtrl.text.isEmpty ||
                        _motivoCtrl.text.startsWith('Compra de')) {
                      _motivoCtrl.text = result.motivoSugerido;
                    }
                  });
                },
              ),
            ],

            // ── SALIDA: campo simple de cantidad ───────────────────────────
            if (!_esIngreso) ...[
              _label('Cantidad (${_insumo?.unidad ?? 'unidad'})'),
              TextFormField(
                controller: _cantidadCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                enabled: !_saving,
                decoration: const InputDecoration(hintText: 'Ej: 25'),
                validator: (v) {
                  final raw = (v ?? '').trim();
                  if (raw.isEmpty) return 'Ingresá una cantidad';
                  final n = double.tryParse(raw.replaceAll(',', '.'));
                  if (n == null) return 'Cantidad inválida';
                  if (n <= 0) return 'Debe ser mayor a 0';
                  if (_tipo == TipoMovimiento.salida && _insumo != null) {
                    if (n > _insumo!.stockActual) {
                      return 'Excede el stock actual '
                          '(${_formatStock(_insumo!.stockActual)})';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'El costo se usará automáticamente del Costo Promedio Ponderado actual.',
                style: AppTypography.caption.copyWith(color: AppColors.textMuted),
              ),
            ],

            const SizedBox(height: AppSpacing.lg),
            _label('Motivo / Observaciones (opcional)'),
            TextFormField(
              controller: _motivoCtrl,
              enabled: !_saving,
              minLines: 2,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: _esIngreso
                    ? 'Ej: Compra de 2 rollos (Total 250m)'
                    : 'Ej: Consumo en orden #123',
                helperText: _esIngreso
                    ? 'Se genera automáticamente. Podés modificarlo.'
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: _saving ? null : _onProcesar,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.brandWhite,
                    ),
                  )
                : const Text('Procesar Movimiento'),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text,
        style: AppTypography.small.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Future<void> _onProcesar() async {
    setState(() {
      _insumoError = _insumo == null ? 'Seleccioná un insumo' : null;
    });

    // Para ingresos: validar calculadora en lugar del form
    if (_esIngreso) {
      if (_insumo == null) return;
      if (!_compraResult.esValido) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Completá los datos de la compra antes de procesar'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
    } else {
      final formOk = _formKey.currentState!.validate();
      if (!formOk || _insumo == null) return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Procesar movimiento'),
        content: Text(
          _esIngreso
              ? 'Se registrará:\n'
                '• ${_formatStock(_compraResult.totalUnidades)} ${_insumo!.unidad} de "${_insumo!.nombre}"\n'
                '• Costo: Bs ${_formatStock(_compraResult.costoUnitario)} / ${_insumo!.unidad}\n\n'
                '¿Confirmás el ingreso?'
              : '¿Estás seguro de procesar esta salida? '
                'Esto modificará el stock del insumo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;
    setState(() => _saving = true);

    final usuario = ref.read(userProfileProvider).value?['nombre'] ?? 'Sistema';
    final motivo = _motivoCtrl.text.trim();

    try {
      if (_esIngreso) {
        await ref.read(movimientoProvider.notifier).crearMovimiento(
              idInsumo: _insumo!.id,
              tipo: TipoMovimiento.ingreso,
              cantidad: _compraResult.totalUnidades,
              motivo: motivo.isEmpty ? _compraResult.motivoSugerido : motivo,
              usuario: usuario,
              costoUnitarioTransaccional: _compraResult.costoUnitario,
            );
      } else {
        final cantidad = double.parse(
            _cantidadCtrl.text.trim().replaceAll(',', '.'));
        await ref.read(movimientoProvider.notifier).crearMovimiento(
              idInsumo: _insumo!.id,
              tipo: _tipo!,
              cantidad: cantidad,
              motivo: motivo,
              usuario: usuario,
              // Para salidas, el trigger sobreescribe el costo con el CPP actual.
              costoUnitarioTransaccional: 0,
            );
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _esIngreso
                ? 'Ingreso registrado: ${_formatStock(_compraResult.totalUnidades)} '
                  '${_insumo!.unidad} @ Bs ${_formatStock(_compraResult.costoUnitario)}'
                : 'Salida registrada correctamente',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al registrar: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  String _formatStock(double n) {
    if (n == n.truncateToDouble()) return n.toInt().toString();
    return n.toStringAsFixed(2);
  }
}
