import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart'; // Para darle formato a las fechas

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class LoteHistorialDialog extends StatefulWidget {
  final String loteId;

  const LoteHistorialDialog({super.key, required this.loteId});

  @override
  State<LoteHistorialDialog> createState() => _LoteHistorialDialogState();
}

class _LoteHistorialDialogState extends State<LoteHistorialDialog> {
  List<dynamic> _historial = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistorial();
  }

  // 👇 LÓGICA BACKEND: JOIN relacional para traer nombres de trabajadores
  Future<void> _fetchHistorial() async {
    try {
      final response = await Supabase.instance.client
          .from('asignaciones_lote')
          .select('''
            fecha_inicio,
            fecha_fin,
            trabajadores (
              profiles (
                nombre,
                apellido
              )
            )
          ''')
          .eq('id_lote', widget.loteId)
          .order('fecha_inicio', ascending: false);

      if (mounted) {
        setState(() {
          _historial = response as List<dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error historial: $e');
      if (mounted) setState(() => _isLoading = false);
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
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cabecera
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Historial del Lote',
                    style: AppTypography.h3.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'ID: ${widget.loteId}',
                  style: AppTypography.small.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const Divider(height: AppSpacing.xl2),

              // Contenido dinámico
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _historial.isEmpty
                    ? _buildEmptyState()
                    : _buildTimeline(),
              ),

              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary500,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return ListView.builder(
      itemCount: _historial.length,
      itemBuilder: (context, index) {
        final item = _historial[index];
        final profile = item['trabajadores']['profiles'];
        final String nombreCompleto =
            "${profile['nombre']} ${profile['apellido']}";

        // Formateo de fecha (ISO a legible)
        final DateTime fecha = DateTime.parse(item['fecha_inicio']).toLocal();
        final String fechaFormateada = DateFormat(
          'dd MMM, HH:mm',
        ).format(fecha);

        final bool esUltimo = index == _historial.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Línea y punto de la línea de tiempo
            Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: AppColors.primary500,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!esUltimo)
                  Container(width: 2, height: 50, color: AppColors.border),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
            // Información del registro
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombreCompleto,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    item['fecha_fin'] == null
                        ? 'Activo actualmente'
                        : 'Finalizado',
                    style: AppTypography.caption.copyWith(
                      color: item['fecha_fin'] == null
                          ? AppColors.primary500
                          : AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    fechaFormateada,
                    style: AppTypography.small.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withOpacity(0.05),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.history_rounded,
            color: AppColors.textSecondary,
            size: 32,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Sin movimientos',
          style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          'Este lote aún no tiene registros en el sistema.',
          textAlign: TextAlign.center,
          style: AppTypography.small.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
