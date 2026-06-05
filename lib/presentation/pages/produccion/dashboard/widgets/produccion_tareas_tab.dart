// ============================================================================
// produccion_tareas_tab.dart
// Ubicación: lib/presentation/pages/produccion/dashboard/widgets/produccion_tareas_tab.dart
// Descripción: Tab "Tareas" del dashboard de producción. Lista reactiva de
// los trabajos asignados al usuario logueado.
//
// Reutiliza misTrabajosProvider (produccion_provider.dart) — mismo origen
// de datos que tenía la página vieja TrabajadorDashboardPage. Migración
// visual con dos cambios respecto al original:
//   - Header de stats deriva los contadores de la lista real
//     (no hardcodeados) y excluye la comparación buggeada contra 'Trabajo:'.
//   - Colores por estado consistentes: ASIGNADO → orange, EN PROCESO →
//     primary500, otros → textMuted.
//
// Tap en card → DetalleTrabajoDialog (mismo flujo del archivo viejo,
// dialog ya vive en components/trabajador/).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/models/trabajo_asignado_model.dart';
import '../../../../components/trabajador/detalle_trabajo_dialog.dart';
import '../../../../providers/produccion_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../../../theme/breakpoints.dart';

// Constraint del ancho de la lista en desktop, para no estirar las cards
// a todo el viewport cuando la ventana es muy ancha.
const double _kMaxContentWidth = 900;

class ProduccionTareasTab extends ConsumerWidget {
  const ProduccionTareasTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trabajosAsync = ref.watch(misTrabajosProvider);
    final isMobile = context.isMobile;

    return trabajosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'Error al cargar tus trabajos:\n$error',
            style: AppTypography.small.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (trabajos) => _TareasBody(trabajos: trabajos, isMobile: isMobile),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// BODY — header de stats + lista
// ═════════════════════════════════════════════════════════════════════════════
class _TareasBody extends StatelessWidget {
  const _TareasBody({required this.trabajos, required this.isMobile});

  final List<TrabajoAsignadoModel> trabajos;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final pendientes = trabajos
        .where((t) => t.estado.toUpperCase() == 'ASIGNADO')
        .length;
    final enProceso = trabajos
        .where((t) => t.estado.toUpperCase() == 'EN PROCESO')
        .length;

    final content = Column(
      children: [
        _StatsHeader(pendientes: pendientes, enProceso: enProceso),
        Expanded(
          child: trabajos.isEmpty
              ? const _EmptyTrabajos()
              : ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: trabajos.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final trabajo = trabajos[index];
                    return _TrabajoCard(
                      trabajo: trabajo,
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (_) => DetalleTrabajoDialog(trabajo: trabajo),
                      ),
                    );
                  },
                ),
        ),
      ],
    );

    if (isMobile) return content;

    // Desktop: centramos la lista y la limitamos para que las cards no se
    // estiren a todo el viewport cuando la ventana es muy ancha.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
        child: content,
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HEADER DE STATS — contadores derivados de la lista real
// ═════════════════════════════════════════════════════════════════════════════
class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.pendientes, required this.enProceso});

  final int pendientes;
  final int enProceso;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          _StatItem(
            label: 'Pendientes',
            count: pendientes,
            color: AppColors.primary500,
          ),
          const SizedBox(width: AppSpacing.xl),
          _StatItem(
            label: 'En Proceso',
            count: enProceso,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
        ),
        Text('$count', style: AppTypography.h2.copyWith(color: color)),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// EMPTY STATE — sin trabajos asignados
// ═════════════════════════════════════════════════════════════════════════════
class _EmptyTrabajos extends StatelessWidget {
  const _EmptyTrabajos();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'No tienes lotes asignados en este momento.',
          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CARD DE TRABAJO — clickeable, abre DetalleTrabajoDialog
// ═════════════════════════════════════════════════════════════════════════════
class _TrabajoCard extends StatelessWidget {
  const _TrabajoCard({required this.trabajo, required this.onTap});

  final TrabajoAsignadoModel trabajo;
  final VoidCallback onTap;

  // Color por estado del trabajo. ASIGNADO usa orange para diferenciarlo
  // visualmente del estado "en proceso" (primary500 / azul de marca).
  Color _colorEstado(String estado) {
    switch (estado.toUpperCase()) {
      case 'ASIGNADO':
        return Colors.orange;
      case 'EN PROCESO':
        return AppColors.primary500;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoColor = _colorEstado(trabajo.estado);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.brandWhite,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Barra lateral de color por estado.
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: estadoColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${trabajo.actividad} · ${trabajo.cliente}',
                    style: AppTypography.small.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lote ${trabajo.loteId} · Cantidad: ${trabajo.cantidad}',
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
                    color: estadoColor,
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
