// ============================================================================
// lib/presentation/pages/admin/plantillas/widgets/plantilla_form_paso4_resumen.dart
// ============================================================================
// Paso 4 del form multi-paso de Plantillas — Resumen y Guardado.
// Lee todo el state del form vía `plantillaFormStateProvider` y los
// catálogos via `tiposPrendaProvider`, `tallasProvider` e `insumosProvider`.
// NO ejecuta el guardado — eso lo coordina el padre (`PlantillaFormPage`)
// desde su botón "Guardar" del footer.
//
// Estructura visual:
//   [Header: "Resumen de la plantilla" + subtítulo]
//   [Banner amarillo en modo crear — alerta de edición parcial]
//   [Sección 1: Información general] — card
//   [Sección 2: Tallas seleccionadas] — chips
//   [Sección 3: Cuadro de medidas] — cards apiladas read-only
//   [Sección 4: Materiales] — lista
//
// Spacing: el body es un Column lineal con SizedBox EXTERNOS de
// AppSpacing.xl entre secciones. Sin margins internos, sin Stack,
// sin mainAxisSize.min. Esto evita la superposición que aparecía en
// mobile con el banner sobre "INFORMACIÓN GENERAL".
//
// DECISIÓN: las medidas se muestran como cards apiladas en TODOS los
// tamaños (no LayoutBuilder adaptativo). Replica el formato del Paso 2
// mobile que el usuario validó visualmente — más legible que la mini-
// tabla horizontal con scroll, especialmente con 4+ tallas.
// RAZÓN: lectura más simple, sin scroll horizontal, alineación clara
// talla → valor. CAMBIAR: si se quiere volver a la tabla horizontal
// para vistas desktop, reemplazar _MedidaResumenCard por la versión
// con columnas previa (ver historial git).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/models/inventario_model.dart';
import '../../../../../domain/models/material_plantilla_model.dart';
import '../../../../../domain/models/plantilla_model.dart';
import '../../../../../domain/models/talla_model.dart';
import '../../../../../domain/models/tipo_prenda_model.dart';
import '../../../../providers/catalogos_provider.dart';
import '../../../../providers/insumo_provider.dart';
import '../../../../providers/plantilla_form_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';

// ─── HELPERS ────────────────────────────────────────────────────────────────

/// Ordena las tallas seleccionadas según su posición en el catálogo (id
/// del catálogo = orden visual canónico S → XXL, t2 → t6). Duplicado del
/// helper en paso2_medidas.dart para evitar import cruzado entre pasos
/// (acoplamiento innecesario). Si crece a 3+ usos, mover a un util
/// compartido (ej. lib/presentation/utils/talla_helpers.dart).
List<int> _ordenarPorCatalogo(
  List<int> tallasSeleccionadas,
  List<TallaModel> catalogo,
) {
  final copia = [...tallasSeleccionadas];
  copia.sort((a, b) {
    final indexA = catalogo.indexWhere((t) => t.id == a);
    final indexB = catalogo.indexWhere((t) => t.id == b);
    final ia = indexA == -1 ? 1 << 30 : indexA;
    final ib = indexB == -1 ? 1 << 30 : indexB;
    return ia.compareTo(ib);
  });
  return copia;
}

// ─── WIDGET PRINCIPAL ───────────────────────────────────────────────────────

class PlantillaFormPaso4Resumen extends ConsumerWidget {
  const PlantillaFormPaso4Resumen({super.key, this.initialPlantilla});

  /// En modo editar, recibe la plantilla original para mostrar la
  /// transición de versiones (era vN → vN+1). En crear, queda null.
  final PlantillaModel? initialPlantilla;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(plantillaFormStateProvider);
    final tiposPrendaAsync = ref.watch(tiposPrendaProvider);
    final tallasAsync = ref.watch(tallasProvider);
    final insumosAsync = ref.watch(inventarioProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── HEADER DEL PASO ──────────────────────────────────────────
          Text('Resumen de la plantilla', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Verificá los datos antes de guardar.',
            style: AppTypography.small.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ─── BANNER (solo en modo crear) ──────────────────────────────
          if (state.mode == 'crear') ...[
            _BannerEdicionParcial(),
            const SizedBox(height: AppSpacing.xl),
          ],

          // ─── 1. INFORMACIÓN GENERAL ──────────────────────────────────
          _SectionTitle('Información general'),
          const SizedBox(height: AppSpacing.sm),
          _InfoGeneralCard(
            state: state,
            tiposPrendaAsync: tiposPrendaAsync,
            initialPlantilla: initialPlantilla,
          ),
          const SizedBox(height: AppSpacing.xl),

          // ─── 2. TALLAS SELECCIONADAS ─────────────────────────────────
          _SectionTitle('Tallas seleccionadas'),
          const SizedBox(height: AppSpacing.sm),
          _TallasResumen(
            tallasSeleccionadas: state.tallasSeleccionadas,
            tallasAsync: tallasAsync,
          ),
          const SizedBox(height: AppSpacing.xl),

          // ─── 3. MATERIALES ───────────────────────────────────────────
          _SectionTitle('Materiales'),
          const SizedBox(height: AppSpacing.sm),
          _MaterialesResumen(
            materiales: state.materiales,
            insumosAsync: insumosAsync,
          ),
        ],
      ),
    );
  }
}

// ─── BANNER DE EDICIÓN PARCIAL ──────────────────────────────────────────────

class _BannerEdicionParcial extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 20,
            color: AppColors.warning,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Revisá bien los datos. Algunos campos (como el tipo de '
              'prenda) pueden tener restricciones de edición una vez '
              'creada la plantilla. Si necesitás cambios mayores, '
              'considerá crear una nueva versión.',
              style: AppTypography.small.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── TÍTULO DE SECCIÓN ──────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
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

// ─── SECCIÓN: INFO GENERAL ──────────────────────────────────────────────────

class _InfoGeneralCard extends StatelessWidget {
  const _InfoGeneralCard({
    required this.state,
    required this.tiposPrendaAsync,
    required this.initialPlantilla,
  });

  final PlantillaFormState state;
  final AsyncValue<List<TipoPrendaModel>> tiposPrendaAsync;
  final PlantillaModel? initialPlantilla;

  String _nombreTipo() {
    if (state.idTipoPrenda == null) return '—';
    return tiposPrendaAsync.when(
      loading: () => 'Cargando...',
      error: (_, _) => 'Error al cargar tipo',
      data: (tipos) {
        final tipo = tipos.where((t) => t.id == state.idTipoPrenda).firstOrNull;
        return tipo?.nombre ?? 'Tipo no disponible';
      },
    );
  }

  String _versionLabel() {
    if (state.mode == 'crear' || initialPlantilla == null) {
      return 'v1 (nueva)';
    }
    final v = initialPlantilla!.version;
    return 'v${v + 1} (era v$v)';
  }

  @override
  Widget build(BuildContext context) {
    final especificacionesVacias = state.especificaciones.trim().isEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InfoRow(label: 'Nombre', value: state.nombre.isEmpty ? '—' : state.nombre),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            label: 'Categoría',
            value: state.categoriaPrenda ?? '—',
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(label: 'Tipo de prenda', value: _nombreTipo()),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(label: 'Versión', value: _versionLabel()),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            label: 'Precio',
            value: state.precioPlantilla > 0
                ? '${state.precioPlantilla.toStringAsFixed(2)} Bs.'
                : 'Sin precio',
          ),
          const SizedBox(height: AppSpacing.sm),
          _InfoRow(
            label: 'T. producción',
            value: state.tiempoProduccionUnitario > 0
                ? '${state.tiempoProduccionUnitario.toStringAsFixed(2)} h/unidad'
                : 'No definido',
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Especificaciones',
            style: AppTypography.small.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          if (especificacionesVacias)
            Text(
              'Sin especificaciones',
              style: AppTypography.small.copyWith(
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            Text(
              state.especificaciones,
              style: AppTypography.small.copyWith(color: AppColors.textPrimary),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: AppTypography.small.copyWith(color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.small.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── SECCIÓN: TALLAS ────────────────────────────────────────────────────────

class _TallasResumen extends StatelessWidget {
  const _TallasResumen({
    required this.tallasSeleccionadas,
    required this.tallasAsync,
  });

  final List<int> tallasSeleccionadas;
  final AsyncValue<List<TallaModel>> tallasAsync;

  @override
  Widget build(BuildContext context) {
    if (tallasSeleccionadas.isEmpty) {
      return const _EmptySection(
        icon: Icons.label_outline,
        titulo: 'Aún no hay tallas seleccionadas',
      );
    }

    return tallasAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(
        'Error al cargar catálogo de tallas: $e',
        style: AppTypography.small.copyWith(color: AppColors.error),
      ),
      data: (catalogo) {
        // Ordenamos por catálogo para que los chips aparezcan en orden
        // canónico (S, M, L, XL...) independiente del orden de selección.
        final ordenadas = _ordenarPorCatalogo(tallasSeleccionadas, catalogo);
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final id in ordenadas)
              _TallaChip(idTalla: id, catalogo: catalogo),
          ],
        );
      },
    );
  }
}

class _TallaChip extends StatelessWidget {
  const _TallaChip({required this.idTalla, required this.catalogo});
  final int idTalla;
  final List<TallaModel> catalogo;

  @override
  Widget build(BuildContext context) {
    final talla = catalogo.where((t) => t.id == idTalla).firstOrNull;
    final esHuerfana = talla == null;
    final label = talla?.nombre ?? 'Talla #$idTalla';
    final color = esHuerfana ? AppColors.textMuted : AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: AppTypography.small.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}


// ─── SECCIÓN: MATERIALES ────────────────────────────────────────────────────

class _MaterialesResumen extends StatelessWidget {
  const _MaterialesResumen({
    required this.materiales,
    required this.insumosAsync,
  });
  final List<MaterialPlantilla> materiales;
  final AsyncValue<List<InventarioItemModel>> insumosAsync;

  @override
  Widget build(BuildContext context) {
    if (materiales.isEmpty) {
      return const _EmptySection(
        icon: Icons.inventory_2_outlined,
        titulo: 'Aún no hay materiales agregados',
      );
    }

    return insumosAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(
        'Error al cargar catálogo de insumos: $e',
        style: AppTypography.small.copyWith(color: AppColors.error),
      ),
      data: (catalogo) {
        double total = 0.0;
        for (final m in materiales) {
          final insumo = catalogo.where((i) => i.id == m.idInsumo).firstOrNull;
          if (insumo != null) {
            total += m.cantidad * insumo.costoUnitario;
          }
        }

        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (var i = 0; i < materiales.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.border),
                _MaterialRow(
                  material: materiales[i],
                  catalogoInsumos: catalogo,
                ),
              ],
              const Divider(height: 1, color: AppColors.border),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppRadius.lg),
                    bottomRight: Radius.circular(AppRadius.lg),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Costo Total Estimado',
                      style: AppTypography.small.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${total.toStringAsFixed(2)} Bs.',
                      style: AppTypography.small.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MaterialRow extends StatelessWidget {
  const _MaterialRow({required this.material, required this.catalogoInsumos});
  final MaterialPlantilla material;
  final List<InventarioItemModel> catalogoInsumos;

  @override
  Widget build(BuildContext context) {
    final insumo = catalogoInsumos
        .where((i) => i.id == material.idInsumo)
        .firstOrNull;

    // Si el insumo no está en el catálogo, mostrar "Insumo no disponible"
    // (puede haber sido desactivado y filtrado del catálogo).
    final huerfano = insumo == null;
    final nombre = insumo?.nombre ?? 'Insumo no disponible';
    final unidad = insumo?.unidad ?? '';

    final costoUnitario = insumo?.costoUnitario ?? 0.0;
    final costoParcial = material.cantidad * costoUnitario;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            size: 16,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              nombre,
              style: AppTypography.small.copyWith(
                color: huerfano
                    ? AppColors.textMuted
                    : AppColors.textSecondary,
                fontStyle: huerfano ? FontStyle.italic : FontStyle.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '${_formatCantidad(material.cantidad)}'
            '${unidad.isNotEmpty ? ' $unidad' : ''}',
            style: AppTypography.small.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 80,
            child: Text(
              '${costoParcial.toStringAsFixed(2)} Bs.',
              textAlign: TextAlign.right,
              style: AppTypography.small.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCantidad(double n) {
    if (n == n.truncateToDouble()) return n.toInt().toString();
    return n.toString();
  }
}

// ─── EMPTY SECTION REUSABLE ─────────────────────────────────────────────────

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.icon, required this.titulo});
  final IconData icon;
  final String titulo;

  // Subtítulo fijo para los empty states — mantiene consistencia.
  static const String _subtitulo =
      'Podés agregarlos editando la plantilla después de guardar.';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 24, color: AppColors.textMuted),
          const SizedBox(height: AppSpacing.xs),
          Text(
            titulo,
            style: AppTypography.small.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            _subtitulo,
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
