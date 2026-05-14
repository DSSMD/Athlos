import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // <-- IMPORTANTE
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../../domain/models/trabajo_asignado_model.dart';
import '../../components/trabajador/detalle_trabajo_dialog.dart';
import '../../providers/produccion_provider.dart'; // 1. Ahora es un ConsumerWidget para poder leer a Riverpod

class TrabajadorDashboardPage extends ConsumerWidget {
  const TrabajadorDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 2. Escuchamos al provider que creaste en el paso anterior
    final trabajosAsync = ref.watch(misTrabajosProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Panel de Trabajo', style: AppTypography.h3),
        backgroundColor: AppColors.brandWhite,
        elevation: 0,
        centerTitle: false,
      ),
      // 3. Manejamos los 3 estados de Riverpod: Cargando, Error y Datos
      body: trabajosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Error de Base de Datos:\n$error\n\nRevisa la consola de VS Code.',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (misTrabajos) {
          return Column(
            children: [
              // Le pasamos la lista real para que calcule los pendientes
              _buildStatsHeader(misTrabajos),

              Expanded(
                child: misTrabajos.isEmpty
                    ? const Center(
                        child: Text(
                          'No tienes lotes asignados en este momento.',
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: misTrabajos.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) {
                          return _TrabajoCard(
                            trabajo: misTrabajos[index],
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => DetalleTrabajoDialog(
                                  trabajo: misTrabajos[index],
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsHeader(List<TrabajoAsignadoModel> misTrabajos) {
    // Calculamos automáticamente los contadores
    final pendientes = misTrabajos
        .where((t) => t.estado.toUpperCase() == 'ASIGNADO')
        .length;
    final enProceso = misTrabajos
        .where((t) => t.estado.toUpperCase() == 'EN PROCESO')
        .length;
    // ...
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: AppColors.brandWhite,
      child: Row(
        children: [
          _statItem('Pendientes', pendientes.toString(), AppColors.primary500),
          const SizedBox(width: AppSpacing.xl),
          _statItem('En Proceso', enProceso.toString(), Colors.orange),
        ],
      ),
    );
  }

  Widget _statItem(String label, String count, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
        Text(count, style: AppTypography.h2.copyWith(color: color)),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TARJETA DE TRABAJO (ESTILO CLEAN)
// ══════════════════════════════════════════════════════════════════════════════
class _TrabajoCard extends StatelessWidget {
  final TrabajoAsignadoModel trabajo;
  final VoidCallback onTap;

  const _TrabajoCard({required this.trabajo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.brandWhite,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: trabajo.estado.toUpperCase() == 'PENDIENTE'
                    ? AppColors.primary500
                    : Colors.orange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${trabajo.actividad} - Lote: ${trabajo.loteId}',
                    style: AppTypography.small.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Cantidad: ${trabajo.cantidad}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${trabajo.fechaAsignacion.day}/${trabajo.fechaAsignacion.month}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  trabajo.estado,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: trabajo.estado.toUpperCase() == 'PENDIENTE'
                        ? AppColors.primary500
                        : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.border,
            ),
          ],
        ),
      ),
    );
  }
}
