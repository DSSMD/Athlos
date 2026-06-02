// lib/presentation/components/produccion/pago_trabajador_dialog.dart

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../providers/pago_provider.dart';

/// Diálogo para que el admin registre un adelanto o liquidación a un trabajador.
///
/// Parámetros requeridos:
/// - [idTrabajador]: UUID del trabajador en la tabla `trabajadores`
/// - [nombreTrabajador]: para mostrar en el título
/// - [numOrden]: para invalidar el provider de resumen al guardar
///
/// Parámetro opcional:
/// - [idAsignacion]: si se sabe exactamente a qué lote pertenece el pago
/// - [saldoPendiente]: pre-rellena el campo de monto con el saldo actual
class PagoTrabajadorDialog extends ConsumerStatefulWidget {
  final String idTrabajador;
  final String nombreTrabajador;
  final String numOrden;
  final String? idAsignacion;
  final double? saldoPendiente;

  const PagoTrabajadorDialog({
    super.key,
    required this.idTrabajador,
    required this.nombreTrabajador,
    required this.numOrden,
    this.idAsignacion,
    this.saldoPendiente,
  });

  @override
  ConsumerState<PagoTrabajadorDialog> createState() =>
      _PagoTrabajadorDialogState();
}

class _PagoTrabajadorDialogState extends ConsumerState<PagoTrabajadorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _montoCtrl;
  final TextEditingController _notasCtrl = TextEditingController();

  String _tipoPago = 'Adelanto';
  bool _guardando = false;

  // 💰 Selección de asignación para asociar el pago
  List<Map<String, dynamic>> _asignacionesPendientes = [];
  String? _asignacionSeleccionada;
  bool _cargandoAsignaciones = false;

  @override
  void initState() {
    super.initState();
    // Pre-rellenar monto si se pasó el saldo pendiente
    final initial = widget.saldoPendiente != null
        ? widget.saldoPendiente!.toStringAsFixed(2)
        : '0.00';
    _montoCtrl = TextEditingController(text: initial);

    // Si no se especificó un lote/asignación, cargamos sus asignaciones pendientes de cobro
    if (widget.idAsignacion == null) {
      _cargarAsignaciones();
    }
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarAsignaciones() async {
    setState(() => _cargandoAsignaciones = true);
    try {
      var query = Supabase.instance.client
          .from('asignaciones_lote')
          .select('''
            id_asignacion,
            monto_acordado,
            estado_pago,
            lote!inner (
              id_lote,
              num_orden,
              plantilla_prenda:id_plantilla (
                nombre
              )
            )
          ''')
          .eq('id_trabajador', widget.idTrabajador)
          .neq('estado_pago', 'Pagado');
      
      // Si estamos en el detalle de una orden, filtramos por esa orden
      if (widget.numOrden != 'global') {
        query = query.eq('lote.num_orden', widget.numOrden);
      }

      final response = await query;
      if (mounted) {
        setState(() {
          _asignacionesPendientes = List<Map<String, dynamic>>.from(response);
          if (_asignacionesPendientes.isNotEmpty) {
            _asignacionSeleccionada = _asignacionesPendientes.first['id_asignacion']?.toString();
            _actualizarMontoSugerido();
          }
          _cargandoAsignaciones = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar asignaciones para pago: $e');
      if (mounted) setState(() => _cargandoAsignaciones = false);
    }
  }

  void _actualizarMontoSugerido() {
    if (widget.idAsignacion != null || _asignacionSeleccionada == null) return;
    try {
      final selected = _asignacionesPendientes.firstWhere(
        (element) => element['id_asignacion']?.toString() == _asignacionSeleccionada,
      );
      final montoAcordado = (selected['monto_acordado'] as num?)?.toDouble() ?? 0.0;
      _montoCtrl.text = montoAcordado.toStringAsFixed(2);
    } catch (_) {}
  }

  Future<void> _guardar() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final idAsignacionFinal = widget.idAsignacion ?? _asignacionSeleccionada;
    if (idAsignacionFinal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El trabajador no tiene trabajos pendientes de pago para asociar.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final monto = double.tryParse(_montoCtrl.text) ?? 0.0;
    if (monto <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El monto debe ser mayor a 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      await ref.read(registrarPagoProvider.notifier).registrar(
            idTrabajador: widget.idTrabajador,
            monto: monto,
            tipoPago: _tipoPago,
            idAsignacion: idAsignacionFinal,
            notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
            numOrden: widget.numOrden,
          );

      if (mounted) {
        Navigator.pop(context, true); // true = pago registrado exitosamente
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$_tipoPago de Bs. ${monto.toStringAsFixed(2)} registrado.',
            ),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _guardando = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.brandWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cabecera ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Registrar Pago',
                            style: AppTypography.h3.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            widget.nombreTrabajador,
                            style: AppTypography.small.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: _guardando ? null : () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // ── Tipo de pago ──────────────────────────────────────────
                Text(
                  'Tipo de pago',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: ['Adelanto', 'Liquidación'].map((tipo) {
                    final selected = _tipoPago == tipo;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: GestureDetector(
                          onTap: _guardando
                              ? null
                              : () => setState(() => _tipoPago = tipo),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary500
                                  : AppColors.neutral100,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.md),
                              border: Border.all(
                                color: selected
                                    ? AppColors.primary500
                                    : AppColors.border,
                              ),
                            ),
                            child: Text(
                              tipo,
                              textAlign: TextAlign.center,
                              style: AppTypography.small.copyWith(
                                color: selected
                                    ? AppColors.brandWhite
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                // Banner informativo para Liquidación
                if (_tipoPago == 'Liquidación') ...[
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withOpacity(0.07),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: const Color(0xFF2563EB).withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Color(0xFF2563EB),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'La liquidación marcará la asignación como "Pagado".',
                            style: AppTypography.caption.copyWith(
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),

                // ── Asignación/Trabajo a pagar (solo si widget.idAsignacion es null) ──
                if (widget.idAsignacion == null) ...[
                  Text(
                    'Lote / Asignación a pagar',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  _cargandoAsignaciones
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      : _asignacionesPendientes.isEmpty
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(AppRadius.md),
                                border: Border.all(color: Colors.orange.withOpacity(0.3)),
                              ),
                              child: Text(
                                'El trabajador no tiene lotes asignados o pendientes de cobro.',
                                style: AppTypography.caption.copyWith(color: Colors.orange),
                              ),
                            )
                          : DropdownButtonFormField<String>(
                              value: _asignacionSeleccionada,
                              dropdownColor: AppColors.brandWhite,
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: AppColors.textSecondary,
                              ),
                              hint: const Text('Seleccionar asignación...'),
                              style: AppTypography.body.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                              ),
                              items: _asignacionesPendientes.map((asig) {
                                final id = asig['id_asignacion'].toString();
                                final loteObj = asig['lote'];
                                final numOrdenLote = loteObj != null ? loteObj['num_orden']?.toString() ?? '?' : '?';
                                final ordCorto = numOrdenLote.length > 8 ? numOrdenLote.substring(0, 8).toUpperCase() : numOrdenLote.toUpperCase();
                                final idLote = loteObj != null ? loteObj['id_lote']?.toString() ?? '?' : '?';
                                final idCorto = idLote.length > 8 ? idLote.substring(0, 8).toUpperCase() : idLote.toUpperCase();
                                final prenda = loteObj != null && loteObj['plantilla_prenda'] != null
                                    ? loteObj['plantilla_prenda']['nombre']?.toString() ?? 'Prenda'
                                    : 'Prenda';
                                final pactado = (asig['monto_acordado'] as num?)?.toDouble() ?? 0.0;
                                final estadoAsig = asig['estado_pago'] ?? 'Pendiente';

                                return DropdownMenuItem<String>(
                                  value: id,
                                  child: Text(
                                    'Ord: $ordCorto · Lote: $idCorto ($prenda) · Bs. $pactado ($estadoAsig)',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              onChanged: _guardando
                                  ? null
                                  : (val) {
                                      setState(() {
                                        _asignacionSeleccionada = val;
                                        _actualizarMontoSugerido();
                                      });
                                    },
                            ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ── Monto ─────────────────────────────────────────────────
                Text(
                  'Monto (Bs)',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _montoCtrl,
                  enabled: !_guardando,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    prefixText: 'Bs. ',
                    hintText: '0.00',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                  validator: (val) {
                    final n = double.tryParse(val ?? '');
                    if (n == null || n <= 0) return 'Ingresa un monto válido';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Notas (opcional) ──────────────────────────────────────
                Text(
                  'Notas (opcional)',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _notasCtrl,
                  enabled: !_guardando,
                  maxLines: 2,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ej: Pago de adelanto semana 1...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl2),

                // ── Botones ───────────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _guardando ? null : _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary500,
                      foregroundColor: AppColors.brandWhite,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      disabledBackgroundColor: AppColors.border,
                    ),
                    child: _guardando
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Confirmar $_tipoPago',
                            style: AppTypography.small.copyWith(
                              color: AppColors.brandWhite,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _guardando ? null : () => Navigator.pop(context),
                    child: Text(
                      'Cancelar',
                      style: AppTypography.small.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
