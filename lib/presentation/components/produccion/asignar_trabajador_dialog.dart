// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../../domain/models/lote_model.dart'; // Asegúrate de que el path sea correcto

class AsignarTrabajadorDialog extends StatefulWidget {
  final LoteModel lote; // Recibimos el objeto completo

  const AsignarTrabajadorDialog({super.key, required this.lote});

  @override
  State<AsignarTrabajadorDialog> createState() =>
      _AsignarTrabajadorDialogState();
}

class _AsignarTrabajadorDialogState extends State<AsignarTrabajadorDialog> {
  String? _trabajadorSeleccionado;
  bool _isLoading = false;

  List<Map<String, dynamic>> _trabajadoresDisponibles = [];
  bool _cargandoLista = true;

  // 💰 Campo para el monto acordado por este lote
  final TextEditingController _montoCtrl = TextEditingController(text: '0.00');
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _cargarTrabajadores();
  }

  @override
  void dispose() {
    _montoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarTrabajadores() async {
    try {
      // Convertimos el idArea (que guardamos en el modelo) a número,
      // porque tu base de datos espera un 'integer'
      final idAreaInt = int.tryParse(widget.lote.idArea) ?? 0;
      // Si imprime "0", era exactamente este problema.

      final response = await Supabase.instance.client
          .from('trabajadores')
          .select('id_trabajador, profiles(nombre, apellido)')
          // 👇 AQUÍ ESTÁ LA SERIALIZACIÓN: Filtramos por el área del lote
          .eq('id_area', idAreaInt);

      if (mounted) {
        setState(() {
          _trabajadoresDisponibles = List<Map<String, dynamic>>.from(response);
          _cargandoLista = false;
        });
      }
    } catch (e) {
      debugPrint('Error al cargar trabajadores: $e');
      if (mounted) setState(() => _cargandoLista = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Dialog(
        backgroundColor: AppColors.brandWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asignar Trabajador',
                  style: AppTypography.h3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Lote ID: ${widget.lote.id}', // Mostramos el UUID real
                  style: AppTypography.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                Text(
                  'Área actual',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  initialValue: widget.lote.areaActual,
                  readOnly: true,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: AppColors.textSecondary.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(
                        color: AppColors.textSecondary.withOpacity(0.1),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(
                        color: AppColors.textSecondary.withOpacity(0.1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                Text(
                  'Trabajadores disponibles',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),

                _cargandoLista
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(8.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : DropdownButtonFormField<String>(
                        initialValue: _trabajadorSeleccionado,
                        dropdownColor: AppColors.brandWhite,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textSecondary,
                        ),
                        hint: Text(
                          _trabajadoresDisponibles.isEmpty
                              ? 'No hay trabajadores en esta área'
                              : 'Seleccionar...',
                          style: AppTypography.small.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
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
                        ),

                        // 👇 AQUÍ ESTÁ EL PASO 3: LA SERIALIZACIÓN DEL DROPDOWN
                        // Busca la parte de los "items:" en tu Dropdown y cámbiala por esto:
                        items: _trabajadoresDisponibles.map((t) {
                          final profile = t['profiles'];

                          // 👇 Sacamos nombre y apellido de forma segura
                          final nombre = profile != null
                              ? (profile['nombre'] ?? '')
                              : '';
                          final apellido = profile != null
                              ? (profile['apellido'] ?? '')
                              : '';

                          // Los unimos (el .trim() quita espacios extra si falta el apellido)
                          final nombreCompleto = '$nombre $apellido'.trim();

                          return DropdownMenuItem<String>(
                            value: t['id_trabajador'].toString(),
                            child: Text(
                              nombreCompleto.isEmpty
                                  ? 'Sin nombre'
                                  : nombreCompleto,
                            ),
                          );
                        }).toList(),

                        onChanged:
                            (_isLoading || _trabajadoresDisponibles.isEmpty)
                            ? null
                            : (value) => setState(
                                () => _trabajadorSeleccionado = value,
                              ),
                      ),
                const SizedBox(height: AppSpacing.lg),

                // ─── MONTO ACORDADO ───────────────────────────────────────
                Text(
                  'Monto acordado por este lote (Bs)',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _montoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  enabled: !_isLoading,
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ej: 350.00',
                    prefixText: 'Bs. ',
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
                    if (n == null || n < 0) {
                      return 'Ingresa un monto válido (0 o más)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl2),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary500,
                      foregroundColor: AppColors.brandWhite,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      elevation: 0,
                      disabledBackgroundColor: AppColors.border,
                    ),
                    onPressed: (_trabajadorSeleccionado == null || _isLoading)
                        ? null
                        : () async {
                            if (!(_formKey.currentState?.validate() ?? false)) {
                              return;
                            }
                            setState(() => _isLoading = true);

                            final montoAcordado =
                                double.tryParse(_montoCtrl.text) ?? 0.0;

                            try {
                              // El INSERT a la tabla asignaciones_lote
                              // incluye ahora monto_acordado y estado_pago='Pendiente' (DEFAULT)
                              await Supabase.instance.client
                                  .from('asignaciones_lote')
                                  .insert({
                                    'id_lote': widget.lote.id,
                                    'id_trabajador': _trabajadorSeleccionado,
                                    'id_estado_asignacion': 1,
                                    'monto_acordado': montoAcordado,
                                  });

                              if (mounted) {
                                Navigator.pop(context, true);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Trabajador asignado con éxito',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _isLoading = false);
                            }
                          },
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Confirmar Asignación',
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
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
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

// ignore_for_file: use_build_context_synchronously
