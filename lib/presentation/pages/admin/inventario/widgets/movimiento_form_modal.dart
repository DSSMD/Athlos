import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/models/inventario_item_model.dart';
import '../../../../../domain/models/movimiento_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/inventario_provider.dart';
import '../../../../providers/movimiento_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../../../theme/breakpoints.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _cantidadCtrl = TextEditingController();
  final _motivoCtrl = TextEditingController();

  InventarioItemModel? _insumo;
  TipoMovimiento? _tipo;
  bool _saving = false;

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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _label('Insumo'),
            DropdownButtonFormField<InventarioItemModel>(
              initialValue: _insumo,
              isExpanded: true,
              items: insumos
                  .map(
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Text(
                        '${i.codigo} — ${i.nombre}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _insumo = v),
              validator: (v) =>
                  v == null ? 'Seleccioná un insumo' : null,
            ),
            if (_insumo != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Stock actual: ${_formatStock(_insumo!.stockActual)} ${_insumo!.unidad}',
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
              items: TipoMovimiento.values
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.label),
                    ),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _tipo = v),
              validator: (v) =>
                  v == null ? 'Seleccioná un tipo' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            _label('Cantidad'),
            TextFormField(
              controller: _cantidadCtrl,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              enabled: !_saving,
              decoration: const InputDecoration(
                hintText: 'Ej: 25',
              ),
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
            const SizedBox(height: AppSpacing.lg),
            _label('Motivo / Observaciones (opcional)'),
            TextFormField(
              controller: _motivoCtrl,
              enabled: !_saving,
              minLines: 3,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Ej: compra a proveedor, ajuste de inventario...',
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
    if (!_formKey.currentState!.validate()) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Procesar movimiento'),
        content: const Text(
          '¿Estás seguro de procesar este movimiento? '
          'Esta acción modificará el stock del insumo.',
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

    final cantidad = double.parse(
      _cantidadCtrl.text.trim().replaceAll(',', '.'),
    );
    final usuario = ref.read(userProfileProvider).value?['nombre'] ?? 'Sistema';

    try {
      await ref
          .read(movimientoProvider.notifier)
          .crearMovimiento(
            insumo: _insumo!,
            tipo: _tipo!,
            cantidad: cantidad,
            motivo: _motivoCtrl.text.trim(),
            usuario: usuario,
          );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Movimiento registrado correctamente'),
          duration: Duration(seconds: 2),
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
