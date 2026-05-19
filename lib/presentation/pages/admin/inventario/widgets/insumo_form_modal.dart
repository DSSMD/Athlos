// lib/presentation/pages/admin/inventario/widgets/insumo_form_modal.dart
//
// Wizard de 2 pasos. NADA se persiste hasta que el usuario confirma en el
// paso 2. Si regresa al paso 1, puede editar libremente sin dejar datos
// huérfanos en la BD.
// ignore_for_file: deprecated_member_use

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/models/movimiento_model.dart';
import '../../../../providers/auth_provider.dart';
import '../../../../providers/insumo_provider.dart';
import '../../../../providers/movimiento_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../../../theme/breakpoints.dart';
import 'compra_calculadora.dart';

void showInsumoFormModal(BuildContext context) {
  if (context.isMobile) {
    Navigator.of(context).push(MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const InsumoFormModal(isMobile: true),
    ));
  } else {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const InsumoFormModal(isMobile: false),
    );
  }
}

class InsumoFormModal extends ConsumerStatefulWidget {
  const InsumoFormModal({super.key, required this.isMobile});
  final bool isMobile;
  @override
  ConsumerState<InsumoFormModal> createState() => _InsumoFormModalState();
}

class _InsumoFormModalState extends ConsumerState<InsumoFormModal> {
  int _paso = 0; // 0 = datos insumo · 1 = ingreso inicial

  // ── Paso 1 ────────────────────────────────────────────────────────────────
  final _formKey1        = GlobalKey<FormState>();
  final _nombreCtrl      = TextEditingController();
  final _stockMinCtrl    = TextEditingController();
  // Atributos estructurados para materiales dimensionables (ej. telas)
  final _anchoCtrl       = TextEditingController(); // ancho en cm
  final _composicionCtrl = TextEditingController(); // ej. "100% algodón"

  late final Future<List<Map<String, dynamic>>> _categoriasFuture;
  List<Map<String, dynamic>> _unidades = [];
  bool    _cargandoUnidades = false;
  String? _errorUnidades;

  int?   _idCategoria;
  String _nombreCategoria = ''; // determina dimensionable
  int?   _idUnidad;
  String _nombreUnidad = '';

  /// El sistema determina automáticamente si es dimensionable (Rollos) según la
  /// unidad de medida. Si se mide en metros, es dimensionable. No depende de la categoría.
  bool get _esDimensionable =>
      _nombreUnidad.toLowerCase().contains('metro') ||
      _nombreUnidad.toLowerCase() == 'm';

  // ── Paso 2 ────────────────────────────────────────────────────────────────
  final _formKey2   = GlobalKey<FormState>();
  final _motivoCtrl = TextEditingController(); // motivo (pre-llenado, editable)
  CompraResult _compraResult = CompraResult.empty;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _categoriasFuture =
        ref.read(inventarioServiceProvider).obtenerCategoriasDropdown();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();      _stockMinCtrl.dispose();
    _anchoCtrl.dispose();       _composicionCtrl.dispose();
    _motivoCtrl.dispose();
    super.dispose();
  }

  // =========================================================================
  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _header(),
        _stepBar(),
        const Divider(height: 1, color: AppColors.border),
        widget.isMobile
            ? Expanded(child: _currentStep())
            : Flexible(child: _currentStep()),
        const Divider(height: 1, color: AppColors.border),
        _actions(),
      ],
    );

    if (widget.isMobile) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: Column(children: [Expanded(child: body)])),
      );
    }
    return Dialog(
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700, maxHeight: 780),
        child: body,
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _header() => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(children: [
          if (_paso == 1)
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              tooltip: 'Volver a datos del material',
              onPressed: _saving ? null : () => setState(() => _paso = 0),
            ),
          Text(
            _paso == 0 ? 'Registrar Material' : 'Ingreso Inicial de Stock',
            style: AppTypography.h2,
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.textPrimary),
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
          ),
        ]),
      );

  // ── Step bar ──────────────────────────────────────────────────────────────
  Widget _stepBar() => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
        child: Row(children: [
          _dot(1, true, 'Datos'),
          _line(_paso >= 1),
          _dot(2, _paso >= 1, 'Ingreso'),
        ]),
      );

  Widget _dot(int n, bool on, String lbl) {
    final c = on ? AppColors.primary500 : AppColors.border;
    return Column(children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: on ? AppColors.primary500 : AppColors.surface,
          border: Border.all(color: c, width: 2),
        ),
        child: Center(
          child: Text('$n',
              style: AppTypography.small.copyWith(
                color: on ? Colors.white : AppColors.textMuted,
                fontWeight: FontWeight.bold,
              )),
        ),
      ),
      const SizedBox(height: 2),
      Text(lbl,
          style: AppTypography.caption
              .copyWith(color: on ? AppColors.primary500 : AppColors.textMuted)),
    ]);
  }

  Widget _line(bool on) => Expanded(
        child: Container(
          height: 2,
          margin: const EdgeInsets.only(bottom: 16),
          color: on ? AppColors.primary500 : AppColors.border,
        ),
      );

  // ── Current step ──────────────────────────────────────────────────────────
  Widget _currentStep() => AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (c, a) => FadeTransition(opacity: a, child: c),
        child: _paso == 0
            ? _paso1(key: const ValueKey(0))
            : _paso2(key: const ValueKey(1)),
      );

  // =========================================================================
  // PASO 1 — datos del insumo
  // =========================================================================
  Widget _paso1({Key? key}) => SingleChildScrollView(
        key: key,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. CATEGORÍA primero — desbloquea el resto del formulario
              _lbl('Categoría *'),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _categoriasFuture,
                builder: (_, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return _loadingField();
                  }
                  if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
                    return const Text(
                        'Error al cargar categorías. Revise su conexión.');
                  }
                  return DropdownButtonFormField<int>(
                    initialValue: _idCategoria,
                    isExpanded: true,
                    hint: const Text('Seleccioná una categoría'),
                    items: snap.data!
                        .map((c) => DropdownMenuItem<int>(
                              value: c['id_categoria'] as int,
                              child: Text(c['nombre_categoria'].toString()),
                            ))
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (v) {
                            final cat = snap.data!.firstWhere(
                              (c) => c['id_categoria'] == v,
                              orElse: () => {'nombre_categoria': ''},
                            );
                            setState(() {
                              _idCategoria = v;
                              _nombreCategoria =
                                  cat['nombre_categoria'].toString();
                              _idUnidad = null;
                              _nombreUnidad = '';
                            });
                            if (v != null) _loadUnidades(v);
                          },
                    validator: (v) =>
                        v == null ? 'Seleccioná una categoría' : null,
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // 2. NOMBRE — habilitado solo tras elegir categoría
              _lbl('Nombre *'),
              TextFormField(
                controller: _nombreCtrl,
                enabled: !_saving && _idCategoria != null,
                decoration: InputDecoration(
                  hintText: _idCategoria == null
                      ? 'Primero seleccioná una categoría'
                      : 'Ej: $_nombreCategoria color azul',
                ),
                validator: (v) {
                  final s = (v ?? '').trim();
                  if (s.isEmpty) return 'Ingresá un nombre';
                  if (ref
                      .read(inventarioProvider.notifier)
                      .nombreYaExiste(s)) {
                    return 'Ya existe un insumo con ese nombre';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // 3. UNIDAD — filtrada por categoría
              _lbl('Unidad de medida *'),
              _unidadesWidget(),
              const SizedBox(height: AppSpacing.lg),

              // 5. STOCK MÍNIMO
              _lbl('Stock mínimo *'),
              TextFormField(
                controller: _stockMinCtrl,
                enabled: !_saving && _idCategoria != null,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  hintText: 'Ej: 50',
                  suffixText: _nombreUnidad.isEmpty ? null : _nombreUnidad,
                  helperText:
                      'Cantidad mínima para no interrumpir la producción',
                ),
                validator: (v) {
                  final n = double.tryParse(
                      (v ?? '').trim().replaceAll(',', '.'));
                  if (n == null) return 'Ingresá un valor numérico';
                  if (n <= 0) return 'Debe ser mayor a 0';
                  return null;
                },
              ),

              // 6. ATRIBUTOS TÉCNICOS — solo para materiales dimensionables
              //    El sistema lo determina automáticamente por categoría.
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                child: _esDimensionable
                    ? Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.lg),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(children: [
                              const Icon(Icons.straighten,
                                  size: 16, color: AppColors.primary500),
                              const SizedBox(width: 6),
                              Text(
                                'Atributos de tela',
                                style: AppTypography.small.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary500),
                              ),
                            ]),
                            const SizedBox(height: AppSpacing.sm),
                            _lbl('Ancho (cm)'),
                            TextFormField(
                              controller: _anchoCtrl,
                              enabled: !_saving,
                              keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                    RegExp(r'[0-9.,]')),
                              ],
                              decoration: const InputDecoration(
                                  hintText: 'Ej: 150',
                                  suffixText: 'cm'),
                              validator: (v) {
                                if ((v ?? '').trim().isEmpty) return null; // opcional
                                final n = double.tryParse(
                                    v!.trim().replaceAll(',', '.'));
                                if (n == null) return 'Valor inválido';
                                if (n <= 0) return 'Debe ser mayor a 0';
                                return null;
                              },
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _lbl('Composición'),
                            TextFormField(
                              controller: _composicionCtrl,
                              enabled: !_saving,
                              decoration: const InputDecoration(
                                hintText: 'Ej: 100% algodón',
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Nada se guarda aún. En el siguiente paso registrarás el '
                'ingreso inicial y todo se creará al mismo tiempo.',
                style:
                    AppTypography.caption.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );

  // =========================================================================
  // PASO 2 — ingreso inicial (solo recolecta datos, no guarda nada todavía)
  // =========================================================================
  Widget _paso2({Key? key}) => SingleChildScrollView(
        key: key,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Resumen del insumo (aún no guardado)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.info_outline,
                          size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text('Pendiente de guardar',
                          style: AppTypography.caption
                              .copyWith(color: AppColors.textMuted)),
                    ]),
                    const SizedBox(height: 6),
                    Text(_nombreCtrl.text.trim(),
                        style: AppTypography.body
                            .copyWith(fontWeight: FontWeight.w600)),
                    Text(
                      'Unidad: $_nombreUnidad  •  Stock mín: ${_stockMinCtrl.text.trim()} $_nombreUnidad',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Badge de tipo fijo
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.success.withOpacity(0.35)),
                ),
                child: Row(children: [
                  const Icon(Icons.arrow_downward,
                      color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Text('Tipo: Ingreso inicial',
                      style: AppTypography.body.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600)),
                ]),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Calculadora de compra
              _lbl('¿Cómo compraste el material?'),
              CompraCalculadora(
                nombreUnidad: _nombreUnidad,
                esDimensionable: _esDimensionable,
                enabled: !_saving,
                onResultChanged: (result) {
                  setState(() {
                    _compraResult = result;
                    // Pre-llenar motivo con el texto sugerido solo si está vacío
                    // o si aún tiene el valor anterior sugerido.
                    if (_motivoCtrl.text.isEmpty ||
                        _motivoCtrl.text.startsWith('Compra de')) {
                      _motivoCtrl.text = result.motivoSugerido;
                    }
                  });
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Motivo (pre-llenado pero editable)
              _lbl('Motivo (opcional)'),
              TextFormField(
                controller: _motivoCtrl,
                enabled: !_saving,
                minLines: 2, maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Ej: Compra de 2 rollos (Total 250m)',
                  helperText: 'Se genera automáticamente. Podés modificarlo.',
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Al confirmar se creará el material y se registrará el '
                'ingreso al mismo tiempo.',
                style: AppTypography.caption.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      );

  // =========================================================================
  // BOTONES
  // =========================================================================
  Widget _actions() => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton(
            onPressed:
                _saving ? null : () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  foregroundColor: AppColors.primary500, // <- Asegura que el texto y el icono sean blancos para que contrasten bien
                ),
            child: const Text('Cancelar'),
          ),
          const SizedBox(width: AppSpacing.sm),
          FilledButton(
            onPressed: _saving
                ? null
                : (_paso == 0 ? _goToStep2 : _confirmarYGuardar),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary500, // <- Define el fondo rojo
                  foregroundColor: Colors
                      .white, // <- Asegura que el texto y el icono sean blancos para que contrasten bien
                ),
            child: _saving
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.brandWhite),
                  )
                : Text(_paso == 0 ? 'Siguiente' : 'Confirmar y Guardar'),
          ),
        ]),
      );

  // =========================================================================
  // LÓGICA: paso 1 → paso 2 (solo validación, sin guardar)
  // =========================================================================
  void _goToStep2() {
    if (!_formKey1.currentState!.validate()) return;
    setState(() => _paso = 1);
  }

  // =========================================================================
  // LÓGICA: confirmar → guardar insumo + ingreso al mismo tiempo
  // =========================================================================
  Future<void> _confirmarYGuardar() async {
    if (!_compraResult.esValido) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completá los datos del ingreso antes de confirmar'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final nombre = _nombreCtrl.text.trim();
    final motivo = _motivoCtrl.text.trim().isEmpty
        ? _compraResult.motivoSugerido
        : _motivoCtrl.text.trim();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg)),
        title: const Text('Confirmar registro'),
        content: Text(
          'Se creará el material "$nombre" y se registrará:\n'
          '• ${_fmt(_compraResult.totalUnidades)} $_nombreUnidad\n'
          '• Costo: Bs ${_fmt(_compraResult.costoUnitario)} / $_nombreUnidad\n\n'
          '¿Deseas continuar?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              style: FilledButton.styleFrom(
                  foregroundColor: AppColors.primary500, // <- Asegura que el texto y el icono sean blancos para que contrasten bien
                ),
              child: const Text('Revisar')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary500, // <- Define el fondo rojo
                  foregroundColor: Colors.white, // <- Asegura que el texto y el icono sean blancos para que contrasten bien
                ),
              child: const Text('Confirmar')),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;
    setState(() => _saving = true);

    try {
      final nuevo = await ref.read(inventarioProvider.notifier).crearInsumo(
            nombre: nombre,
            idCategoria: _idCategoria!,
            stockMinimo: double.parse(
                _stockMinCtrl.text.trim().replaceAll(',', '.')),
            idUnidad: _idUnidad!,
            dimensionable: _esDimensionable,
            atributosTecnicosJson: _buildAtributosTecnicosJson(),
          );

      final usuario =
          ref.read(userProfileProvider).value?['nombre'] ?? 'Sistema';
      await ref.read(movimientoProvider.notifier).crearMovimiento(
            idInsumo: nuevo.id,
            tipo: TipoMovimiento.ingreso,
            cantidad: _compraResult.totalUnidades,
            motivo: motivo,
            usuario: usuario,
            costoUnitarioTransaccional: _compraResult.costoUnitario,
          );

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Material "$nombre" creado • '
            '${_fmt(_compraResult.totalUnidades)} $_nombreUnidad '
            '@ Bs ${_fmt(_compraResult.costoUnitario)}/$_nombreUnidad',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }


  // =========================================================================
  // UNIDADES — carga filtrada por categoria_unidad
  // =========================================================================
  Future<void> _loadUnidades(int idCategoria) async {
    setState(() {
      _cargandoUnidades = true;
      _errorUnidades = null;
      _unidades = [];
    });
    try {
      final list = await ref
          .read(inventarioServiceProvider)
          .obtenerUnidadesPorCategoria(idCategoria);
      if (!mounted) return;
      setState(() {
        _unidades = list;
        _cargandoUnidades = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _cargandoUnidades = false;
        _errorUnidades = 'Error al cargar unidades. Verifica tu conexión.';
      });
    }
  }

  Widget _unidadesWidget() {
    if (_idCategoria == null) {
      return InputDecorator(
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
        child: Text('Seleccioná primero una categoría',
            style: AppTypography.body.copyWith(color: AppColors.textMuted)),
      );
    }
    if (_cargandoUnidades) return _loadingField();
    if (_errorUnidades != null) {
      return Row(children: [
        Expanded(
            child: Text(_errorUnidades!,
                style: AppTypography.small.copyWith(color: AppColors.error))),
        TextButton.icon(
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Reintentar'),
          onPressed: () => _loadUnidades(_idCategoria!),
        ),
      ]);
    }
    return DropdownButtonFormField<int>(
      initialValue: _idUnidad,
      isExpanded: true,
      hint: const Text('Seleccioná una unidad'),
      items: _unidades
          .map((u) => DropdownMenuItem<int>(
                value: u['id_unidad'] as int,
                child: Text(u['nom_unidad'].toString()),
              ))
          .toList(),
      onChanged: _saving
          ? null
          : (v) {
              final nombre = _unidades
                  .firstWhere((u) => u['id_unidad'] == v,
                      orElse: () => {'nom_unidad': ''})['nom_unidad']
                  .toString();
              setState(() {
                _idUnidad = v;
                _nombreUnidad = nombre;
              });
            },
      validator: (v) => v == null ? 'Seleccioná una unidad' : null,
    );
  }

  // =========================================================================
  // ATRIBUTOS TÉCNICOS — construidos por código, no por el usuario
  // =========================================================================
  /// Arma el JSON de atributos técnicos a partir de los campos estructurados.
  /// El usuario nunca escribe JSON a mano: llena campos normales y el sistema
  /// serializa por él. Solo aplica cuando [_esDimensionable] es true.
  String? _buildAtributosTecnicosJson() {
    if (!_esDimensionable) return null;
    final mapa = <String, dynamic>{};
    final ancho = double.tryParse(
        _anchoCtrl.text.trim().replaceAll(',', '.'));
    if (ancho != null && ancho > 0) mapa['ancho_cm'] = ancho;
    final composicion = _composicionCtrl.text.trim();
    if (composicion.isNotEmpty) mapa['composicion'] = composicion;
    return mapa.isEmpty ? null : jsonEncode(mapa);
  }

  // =========================================================================
  // HELPERS
  // =========================================================================
  Widget _loadingField() => InputDecorator(
        decoration: const InputDecoration(),
        child: Row(children: [
          Expanded(
              child: Text('Cargando...',
                  style: AppTypography.body
                      .copyWith(color: AppColors.textMuted))),
          const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.textMuted)),
        ]),
      );

  Widget _lbl(String t) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Text(t,
            style: AppTypography.small.copyWith(
                fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      );

  String _fmt(double n) =>
      n == n.truncateToDouble() ? n.toInt().toString() : n.toStringAsFixed(2);
}
