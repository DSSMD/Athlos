// ============================================================================
// lib/presentation/pages/admin/plantillas/widgets/plantilla_form_paso2_medidas.dart
// ============================================================================
// Paso 2 del form multi-paso de Plantillas — Selección de Tallas.
// (Anteriormente incluía una matriz compleja de medidas punto a punto,
// que fue removida temporalmente para simplificar el MVP).
//
// Estructura:
// - Sección "Tallas" con chips multi-select (FilterChip) cargados desde
//   `tallasProvider`.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/models/talla_model.dart';
import '../../../../providers/catalogos_provider.dart';
import '../../../../providers/plantilla_form_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';

class PlantillaFormPaso2Medidas extends ConsumerWidget {
  const PlantillaFormPaso2Medidas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(plantillaFormStateProvider);
    final notifier = ref.read(plantillaFormStateProvider.notifier);
    final tallasAsync = ref.watch(tallasProvider);

    return tallasAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'Error al cargar tallas: $e',
            style: AppTypography.small.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      data: (catalogoTallas) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Selección de Tallas', style: AppTypography.h3),
              const SizedBox(height: 2),
              Text(
                'Definí en qué tallas se confeccionará esta plantilla.',
                style: AppTypography.small.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              _SectionLabel('Tallas Disponibles'),
              const SizedBox(height: AppSpacing.sm),
              _SelectorTallas(
                catalogo: catalogoTallas,
                tallasSeleccionadas: state.tallasSeleccionadas,
                onToggle: (idTalla) {
                  final seleccionadas = [...state.tallasSeleccionadas];
                  if (seleccionadas.contains(idTalla)) {
                    seleccionadas.remove(idTalla);
                  } else {
                    seleccionadas.add(idTalla);
                  }
                  notifier.setTallasSeleccionadas(seleccionadas);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SelectorTallas extends StatelessWidget {
  const _SelectorTallas({
    required this.catalogo,
    required this.tallasSeleccionadas,
    required this.onToggle,
  });

  final List<TallaModel> catalogo;
  final List<int> tallasSeleccionadas;
  final ValueChanged<int> onToggle;

  @override
  Widget build(BuildContext context) {
    if (catalogo.isEmpty) {
      return Text(
        'No hay tallas en el catálogo. Pedir a Mel que cargue la tabla `tallas`.',
        style: AppTypography.small.copyWith(color: AppColors.textMuted),
      );
    }
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final t in catalogo)
          FilterChip(
            label: Text(t.nombre),
            selected: tallasSeleccionadas.contains(t.id),
            onSelected: (_) => onToggle(t.id),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.caption.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}
