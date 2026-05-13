import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../../domain/models/trabajo_asignado_model.dart';
import '../../components/trabajador/detalle_trabajo_dialog.dart'; // Crearemos este a continuación

class TrabajadorDashboardPage extends StatefulWidget {
  const TrabajadorDashboardPage({super.key});

  @override
  State<TrabajadorDashboardPage> createState() => _TrabajadorDashboardPageState();
}

class _TrabajadorDashboardPageState extends State<TrabajadorDashboardPage> {
  // TODO: BACKEND - Esta lista vendrá de tu Provider filtrada por el ID del usuario logueado
  final List<TrabajoAsignadoModel> _misTrabajos = [
    TrabajoAsignadoModel(
      loteId: '#LT-2045',
      ordenId: '#ORD-889',
      cliente: 'Textiles Athlos',
      estado: 'PENDIENTE',
      fechaAsignacion: DateTime.now(),
      cantidad: 250,
      tallas: ['S', 'M', 'L'],
      instrucciones: 'Usar patrón de corte tipo Slim Fit. Cuidado con el desperdicio en las esquinas.',
    ),
  ];

  void _verDetalle(TrabajoAsignadoModel trabajo) {
    showDialog(
      context: context,
      builder: (context) => DetalleTrabajoDialog(trabajo: trabajo),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Mantenemos el fondo del sistema
      appBar: AppBar(
        title: Text('Panel de Trabajo', style: AppTypography.h3),
        backgroundColor: AppColors.brandWhite,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          // Resumen rápido en la parte superior
          _buildStatsHeader(),
          
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: _misTrabajos.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                return _TrabajoCard(
                  trabajo: _misTrabajos[index],
                  onTap: () => _verDetalle(_misTrabajos[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      color: AppColors.brandWhite,
      child: Row(
        children: [
          _statItem('Pendientes', '1', AppColors.primary500),
          const SizedBox(width: AppSpacing.xl),
          _statItem('En Proceso', '0', Colors.orange),
        ],
      ),
    );
  }

  Widget _statItem(String label, String count, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: AppColors.textSecondary)),
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
            // Indicador visual de estado
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: trabajo.estado == 'PENDIENTE' ? AppColors.primary500 : Colors.orange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            
            // Información principal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trabajo.loteId, 
                    style: AppTypography.small.copyWith(fontWeight: FontWeight.bold, color: AppColors.textPrimary)
                  ),
                ],
              ),
            ),
            
            // Fecha y Estado
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${trabajo.fechaAsignacion.day}/${trabajo.fechaAsignacion.month}', 
                  style: AppTypography.caption.copyWith(color: AppColors.textSecondary)
                ),
                const SizedBox(height: 4),
                Text(
                  trabajo.estado, 
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold, 
                    color: trabajo.estado == 'PENDIENTE' ? AppColors.primary500 : Colors.orange
                  )
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.border),
          ],
        ),
      ),
    );
  }
}