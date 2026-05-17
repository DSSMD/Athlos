// lib/presentation/pages/admin/plantillas/widgets/plantilla_detalle_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../../../../domain/models/plantilla_model.dart';
import '../../../../providers/catalogos_provider.dart';

class PlantillaDetalleDialog extends ConsumerWidget {
  final PlantillaModel plantilla;

  const PlantillaDetalleDialog({super.key, required this.plantilla});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchar catálogos para resolver IDs a Nombres
    final tiposPrendaAsync = ref.watch(tiposPrendaProvider);
    final tallasAsync = ref.watch(tallasProvider);
    final insumosAsync = ref.watch(insumosProvider);

    return Dialog(
      backgroundColor: AppColors.brandWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera con Badge de Estado
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Detalle de la Plantilla', style: AppTypography.h3),
                        Text('ID: ${plantilla.id}',
                            style: AppTypography.small
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  _StatusChip(activa: plantilla.activa),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Información Principal
              _buildInfoSection('NOMBRE', plantilla.nombre),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildInfoSection(
                      'TIPO PRENDA',
                      tiposPrendaAsync.when(
                        data: (tipos) => plantilla.nombreTipoPrenda(tipos),
                        loading: () => 'Cargando...',
                        error: (_, _) => 'Error',
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildInfoSection('VERSIÓN', plantilla.versionLabel),
                  ),
                ],
              ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildInfoSection(
                      'PRECIO BASE',
                      '${plantilla.precioPlantilla.toStringAsFixed(2)} Bs.',
                      isHighlight: true,
                    ),
                  ),
                  Expanded(
                    child: _buildInfoSection(
                      'CREADA EL',
                      '${plantilla.createdAt.day}/${plantilla.createdAt.month}/${plantilla.createdAt.year}',
                    ),
                  ),
                ],
              ),

              if (plantilla.especificaciones.isNotEmpty)
                _buildInfoSection('ESPECIFICACIONES', plantilla.especificaciones),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Divider(color: AppColors.border),
              ),

              // ─── TALLAS SELECCIONADAS ───
              Text(
                'TALLAS DISPONIBLES (${plantilla.tallasSeleccionadas.length})',
                style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              tallasAsync.when(
                data: (tallas) {
                  final seleccionadas = tallas
                      .where((t) => plantilla.tallasSeleccionadas.contains(t.id))
                      .map((t) => t.nombre)
                      .toList();

                  if (seleccionadas.isEmpty) {
                    return _buildEmptyState('No hay tallas configuradas.');
                  }

                  return Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: seleccionadas
                        .map((t) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.neutral100,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(t,
                                  style: AppTypography.small.copyWith(
                                      fontWeight: FontWeight.bold)),
                            ))
                        .toList(),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (_, _) => const Text('Error cargando tallas.'),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Divider(color: AppColors.border),
              ),

              // ─── MATERIALES REQUERIDOS (RECETA) ───
              Text(
                'MATERIALES (RECETA) (${plantilla.materiales.length})',
                style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),

              Flexible(
                child: plantilla.materiales.isEmpty
                    ? _buildEmptyState('Esta plantilla no requiere materiales.')
                    : insumosAsync.when(
                        data: (insumos) {
                          return ListView.separated(
                            shrinkWrap: true,
                            itemCount: plantilla.materiales.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              final mat = plantilla.materiales[index];
                              // Buscar el insumo en el catálogo
                              final insumo = insumos.firstWhere(
                                (i) => i.id == mat.idInsumo,
                                orElse: () => throw Exception('Not found'), // Handle in real code
                              );
                              
                              final nombreInsumo = insumo.nombre;
                              final unidadInsumo = insumo.unidad;

                              return Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: AppColors.brandWhite,
                                  border: Border.all(color: AppColors.border),
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.md),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                          color: AppColors.primary500
                                              .withValues(alpha: 0.1),
                                          shape: BoxShape.circle),
                                      child: const Icon(Icons.inventory_2_outlined,
                                          size: 16,
                                          color: AppColors.primary500),
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Text(nombreInsumo,
                                          style: AppTypography.small.copyWith(
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    Text(
                                      '${mat.cantidad} $unidadInsumo',
                                      style: AppTypography.small.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const LinearProgressIndicator(),
                        error: (_, _) => const Text('Error cargando insumos.'),
                      ),
              ),

              const SizedBox(height: AppSpacing.xl2),

              // Botón de Cierre
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary500,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.md)),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String label, String value,
      {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.body.copyWith(
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: isHighlight ? AppColors.primary500 : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Center(
        child: Text(msg,
            textAlign: TextAlign.center,
            style: AppTypography.small
                .copyWith(color: AppColors.textSecondary)),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool activa;
  const _StatusChip({required this.activa});

  @override
  Widget build(BuildContext context) {
    final color = activa ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20)),
      child: Text(
        activa ? 'ACTIVA' : 'INACTIVA',
        style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1),
      ),
    );
  }
}
