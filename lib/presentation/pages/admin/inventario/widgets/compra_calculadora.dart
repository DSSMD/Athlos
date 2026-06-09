// lib/presentation/pages/admin/inventario/widgets/compra_calculadora.dart
//
// Widget reutilizable que actúa como "calculadora de compra". El usuario
// elige cómo vino empacado el material y el widget calcula automáticamente:
//   - cantidad total en unidades mínimas
//   - costo por unidad mínima
//   - motivo sugerido (texto listo para guardar)
//
// Se usa en el wizard de alta (Paso 2) y en el form de movimiento standalone.
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';

// ─── Resultado que el padre recibe en cada cambio ────────────────────────────

class CompraResult {
  const CompraResult({
    required this.totalUnidades,
    required this.costoUnitario,
    required this.motivoSugerido,
    required this.esValido,
  });

  /// Cantidad en unidades mínimas (conos, metros, kg…)
  final double totalUnidades;

  /// Costo por unidad mínima — se envía como `costo_unitario_transaccional`
  final double costoUnitario;

  /// Motivo auto-generado, listo para el campo "Motivo" del movimiento
  final String motivoSugerido;

  /// True cuando hay datos suficientes para proceder al guardado
  final bool esValido;

  static const empty = CompraResult(
    totalUnidades: 0,
    costoUnitario: 0,
    motivoSugerido: '',
    esValido: false,
  );
}

// ─── Modalidades de compra ────────────────────────────────────────────────────

enum ModalidadCompra {
  unidadMinima, // ingreso directo en unidad mínima + costo por unidad
  agrupado,     // por cajas (no-dimensionable) o por rollos (dimensionable)
}

// ─── Widget ───────────────────────────────────────────────────────────────────

class CompraCalculadora extends StatefulWidget {
  const CompraCalculadora({
    super.key,
    required this.nombreUnidad,
    required this.esDimensionable,
    required this.onResultChanged,
    this.enabled = true,
  });

  /// Nombre de la unidad mínima (ej. "metro", "cono", "kg")
  final String nombreUnidad;

  /// Si true → el modo agrupado se llama "Por rollo".
  /// Si false → se llama "Por caja".
  final bool esDimensionable;

  /// Se llama cada vez que cambia cualquier campo.
  final ValueChanged<CompraResult> onResultChanged;

  final bool enabled;

  @override
  State<CompraCalculadora> createState() => _CompraCalculadoraState();
}

class _CompraCalculadoraState extends State<CompraCalculadora> {
  ModalidadCompra _modalidad = ModalidadCompra.unidadMinima;

  // ── Modo "Unidad mínima" ──────────────────────────────────────────────────
  final _cantidadCtrl    = TextEditingController();
  final _costoUnitCtrl   = TextEditingController(); // costo por unidad

  // ── Modo "Agrupado" (caja / rollo) ───────────────────────────────────────
  final _gruposCtrl      = TextEditingController(); // cajas o rollos
  final _porGrupoCtrl    = TextEditingController(); // unidades por caja (solo caja)
  final _totalMetrosCtrl = TextEditingController(); // metros totales (solo rollo)
  final _costoFacturaCtrl = TextEditingController(); // costo total factura

  @override
  void dispose() {
    _cantidadCtrl.dispose();    _costoUnitCtrl.dispose();
    _gruposCtrl.dispose();      _porGrupoCtrl.dispose();
    _totalMetrosCtrl.dispose(); _costoFacturaCtrl.dispose();
    super.dispose();
  }

  // ── Helpers numéricos ─────────────────────────────────────────────────────

  double _n(TextEditingController c) =>
      double.tryParse(c.text.trim().replaceAll(',', '.')) ?? 0;

  String _fmt(double n) =>
      n == n.truncateToDouble() ? n.toInt().toString() : n.toStringAsFixed(2);

  static final _numFmt = [FilteringTextInputFormatter.digitsOnly];
  static final _decFmt = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];

  // ── Cálculo central ───────────────────────────────────────────────────────

  CompraResult _calcular() {
    switch (_modalidad) {
      case ModalidadCompra.unidadMinima:
        final cant  = _n(_cantidadCtrl);
        final costo = _n(_costoUnitCtrl);
        if (cant <= 0 || costo <= 0) return CompraResult.empty;
        return CompraResult(
          totalUnidades: cant,
          costoUnitario: costo,
          motivoSugerido:
              'Compra de ${_fmt(cant)} ${widget.nombreUnidad}',
          esValido: true,
        );

      case ModalidadCompra.agrupado:
        final grupos  = _n(_gruposCtrl);
        final factura = _n(_costoFacturaCtrl);
        if (grupos <= 0 || factura <= 0) return CompraResult.empty;

        if (widget.esDimensionable) {
          // ROLLO: el usuario da metros totales
          final metros = _n(_totalMetrosCtrl);
          if (metros <= 0) return CompraResult.empty;
          final costoU = factura / metros;
          return CompraResult(
            totalUnidades: metros,
            costoUnitario: costoU,
            motivoSugerido:
                'Compra de ${_fmt(grupos)} rollo${grupos != 1 ? "s" : ""} '
                '(Total ${_fmt(metros)}m)',
            esValido: true,
          );
        } else {
          // CAJA: el usuario da unidades por caja
          final porCaja = _n(_porGrupoCtrl);
          if (porCaja <= 0) return CompraResult.empty;
          final total = grupos * porCaja;
          final costoU = factura / total;
          return CompraResult(
            totalUnidades: total,
            costoUnitario: costoU,
            motivoSugerido:
                'Compra de ${_fmt(grupos)} caja${grupos != 1 ? "s" : ""} '
                '(${_fmt(total)} ${widget.nombreUnidad})',
            esValido: true,
          );
        }
    }
  }

  void _notificar() {
    widget.onResultChanged(_calcular());
    setState(() {}); // reconstruir resumen
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final result = _calcular();
    final label = widget.esDimensionable ? 'Por rollo' : 'Por caja';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Selector de modalidad ───────────────────────────────────────────
        SegmentedButton<ModalidadCompra>(
          segments: [
            ButtonSegment(
              value: ModalidadCompra.unidadMinima,
              label: Text('Por ${widget.nombreUnidad}'),
              icon: const Icon(Icons.straighten, size: 16),
            ),
            ButtonSegment(
              value: ModalidadCompra.agrupado,
              label: Text(label),
              icon: Icon(
                widget.esDimensionable
                    ? Icons.rotate_90_degrees_cw_outlined
                    : Icons.inventory_2_outlined,
                size: 16,
              ),
            ),
          ],
          selected: {_modalidad},
          onSelectionChanged: widget.enabled
              ? (s) {
                  setState(() => _modalidad = s.first);
                  _notificar();
                }
              : null,
          style: const ButtonStyle(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Campos dinámicos ────────────────────────────────────────────────
        if (_modalidad == ModalidadCompra.unidadMinima) ...[
          _campo(
            label: 'Cantidad (${widget.nombreUnidad}s) *',
            ctrl: _cantidadCtrl,
            hint: 'Ej: 36',
            fmt: _numFmt,
            suffix: widget.nombreUnidad,
          ),
          const SizedBox(height: AppSpacing.md),
          _campo(
            label: 'Costo por ${widget.nombreUnidad} *',
            ctrl: _costoUnitCtrl,
            hint: 'Ej: 5.00',
            fmt: _decFmt,
            suffix: 'Bs/${widget.nombreUnidad}',
          ),
        ] else if (widget.esDimensionable) ...[
          // ROLLO
          _campo(
            label: 'Cantidad de rollos *',
            ctrl: _gruposCtrl,
            hint: 'Ej: 2',
            fmt: _numFmt,
            suffix: 'rollos',
          ),
          const SizedBox(height: AppSpacing.md),
          _campo(
            label: 'Metros totales (todos los rollos) *',
            ctrl: _totalMetrosCtrl,
            hint: 'Ej: 250',
            fmt: _decFmt,
            suffix: 'm',
          ),
          const SizedBox(height: AppSpacing.md),
          _campo(
            label: 'Costo total de la factura *',
            ctrl: _costoFacturaCtrl,
            hint: 'Ej: 1250.00',
            fmt: _decFmt,
            suffix: 'Bs',
          ),
        ] else ...[
          // CAJA
          _campo(
            label: 'Cantidad de cajas *',
            ctrl: _gruposCtrl,
            hint: 'Ej: 3',
            fmt: _numFmt,
            suffix: 'cajas',
          ),
          const SizedBox(height: AppSpacing.md),
          _campo(
            label: '${widget.nombreUnidad.capitalize()}s por caja *',
            ctrl: _porGrupoCtrl,
            hint: 'Ej: 12',
            fmt: _numFmt,
            suffix: '${widget.nombreUnidad}/caja',
          ),
          const SizedBox(height: AppSpacing.md),
          _campo(
            label: 'Costo total de la factura *',
            ctrl: _costoFacturaCtrl,
            hint: 'Ej: 540.00',
            fmt: _decFmt,
            suffix: 'Bs',
          ),
        ],

        const SizedBox(height: AppSpacing.md),

        // ── Resumen calculado ───────────────────────────────────────────────
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: result.esValido
                ? AppColors.successBg
                : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: result.esValido
                  ? AppColors.success.withOpacity(0.4)
                  : AppColors.border,
            ),
          ),
          child: result.esValido
              ? Row(children: [
                  const Icon(Icons.check_circle_outline,
                      color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_fmt(result.totalUnidades)} ${widget.nombreUnidad}  •  '
                      'Bs ${_fmt(result.costoUnitario)} / ${widget.nombreUnidad}  •  '
                      'Total Bs ${_fmt(result.totalUnidades * result.costoUnitario)}',
                      style: AppTypography.small.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ])
              : Text(
                  'Completá los campos para ver el resumen',
                  style:
                      AppTypography.small.copyWith(color: AppColors.textMuted),
                ),
        ),
      ],
    );
  }

  Widget _campo({
    required String label,
    required TextEditingController ctrl,
    required String hint,
    required List<TextInputFormatter> fmt,
    String? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label,
            style: AppTypography.small.copyWith(
                fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: ctrl,
          enabled: widget.enabled,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: fmt,
          decoration: InputDecoration(hintText: hint, suffixText: suffix),
          onChanged: (_) => _notificar(),
        ),
      ],
    );
  }
}

extension _StringExt on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}
