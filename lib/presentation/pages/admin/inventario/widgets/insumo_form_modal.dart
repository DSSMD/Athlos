import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/models/inventario_item_model.dart';
import '../../../../providers/inventario_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../../../theme/breakpoints.dart';

/// Abre el modal "Registrar un Material" (alta de insumo).
///
/// Desktop: Dialog centrado (700×750). Mobile: fullscreen route.
void showInsumoFormModal(BuildContext context) {
  if (context.isMobile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const InsumoFormModal(isMobile: true),
      ),
    );
  } else {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const InsumoFormModal(isMobile: false),
    );
  }
}

const _kUnidades = ['m', 'cm', 'kg', 'unidades'];

class InsumoFormModal extends ConsumerStatefulWidget {
  const InsumoFormModal({super.key, required this.isMobile});

  final bool isMobile;

  @override
  ConsumerState<InsumoFormModal> createState() => _InsumoFormModalState();
}

class _InsumoFormModalState extends ConsumerState<InsumoFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _stockMinCtrl = TextEditingController();
  final _costoCtrl = TextEditingController();
  final _atributosCtrl = TextEditingController();

  CategoriaInsumo? _categoria;
  String? _unidad;
  bool _dimensionable = false;
  bool _saving = false;

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _stockMinCtrl.dispose();
    _costoCtrl.dispose();
    _atributosCtrl.dispose();
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
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 750),
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
          Text('Registrar un Material', style: AppTypography.h2),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _label('Nombre *'),
            TextFormField(
              controller: _nombreCtrl,
              enabled: !_saving,
              decoration: const InputDecoration(
                hintText: 'Ej: Hilo negro #120',
              ),
              validator: (v) {
                final raw = (v ?? '').trim();
                if (raw.isEmpty) return 'Ingresá un nombre';
                final existe = ref
                    .read(inventarioProvider.notifier)
                    .nombreYaExiste(raw);
                if (existe) return 'Ya existe un insumo con ese nombre';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _label('Categoría *'),
            DropdownButtonFormField<CategoriaInsumo>(
              initialValue: _categoria,
              isExpanded: true,
              items: CategoriaInsumo.values
                  .map(
                    (c) =>
                        DropdownMenuItem(value: c, child: Text(c.label)),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _categoria = v),
              validator: (v) =>
                  v == null ? 'Seleccioná una categoría' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            _label('Unidad de medida *'),
            DropdownButtonFormField<String>(
              initialValue: _unidad,
              isExpanded: true,
              items: _kUnidades
                  .map(
                    (u) => DropdownMenuItem(value: u, child: Text(u)),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (v) => setState(() => _unidad = v),
              validator: (v) =>
                  v == null ? 'Seleccioná una unidad' : null,
            ),
            const SizedBox(height: AppSpacing.lg),
            _label('Stock mínimo *'),
            TextFormField(
              controller: _stockMinCtrl,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(hintText: 'Ej: 50'),
              validator: (v) {
                final raw = (v ?? '').trim();
                if (raw.isEmpty) return 'Ingresá un stock mínimo';
                final n = double.tryParse(raw.replaceAll(',', '.'));
                if (n == null) return 'Valor inválido';
                if (n <= 0) return 'Debe ser mayor a 0';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _label('Costo unitario *'),
            TextFormField(
              controller: _costoCtrl,
              enabled: !_saving,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(hintText: 'Ej: 8.50'),
              validator: (v) {
                final raw = (v ?? '').trim();
                if (raw.isEmpty) return 'Ingresá un costo unitario';
                final n = double.tryParse(raw.replaceAll(',', '.'));
                if (n == null) return 'Valor inválido';
                if (n <= 0) return 'Debe ser mayor a 0';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '¿Es material dimensionable? (Tela)',
                    style: AppTypography.body,
                  ),
                ),
                Switch(
                  value: _dimensionable,
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => _dimensionable = v),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: _dimensionable
                  ? Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _label('Atributos técnicos (JSON)'),
                          // TODO: Den definirá el formato exacto del JSON.
                          // Por ahora textarea libre.
                          TextFormField(
                            controller: _atributosCtrl,
                            enabled: !_saving,
                            minLines: 4,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText: 'Ej: {"ancho": 150, "alto": 100}',
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'El stock inicia en 0. Una vez creado, no podrás cambiar estos '
              'datos.',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
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
            onPressed: _saving ? null : _onGuardar,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.brandWhite,
                    ),
                  )
                : const Text('Guardar'),
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

  Future<void> _onGuardar() async {
    if (!_formKey.currentState!.validate()) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: const Text('Confirmar alta'),
        content: const Text(
          '¿Estás seguro de agregar este insumo? No podrá cambiar luego.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Atrás'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;

    setState(() => _saving = true);

    final notifier = ref.read(inventarioProvider.notifier);
    final codigo = notifier.generarSiguienteCodigo();
    final stockMin = double.parse(
      _stockMinCtrl.text.trim().replaceAll(',', '.'),
    );
    final costo = double.parse(
      _costoCtrl.text.trim().replaceAll(',', '.'),
    );
    final atributos = _atributosCtrl.text.trim();

    try {
      final nuevo = await notifier.crearInsumo(
        codigo: codigo,
        nombre: _nombreCtrl.text.trim(),
        categoria: _categoria!,
        stockMinimo: stockMin,
        unidad: _unidad!,
        costoUnitario: costo,
        dimensionable: _dimensionable,
        atributosTecnicosJson:
            _dimensionable && atributos.isNotEmpty ? atributos : null,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insumo ${nuevo.codigo} creado correctamente'),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
