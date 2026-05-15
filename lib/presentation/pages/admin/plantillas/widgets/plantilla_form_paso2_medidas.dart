// ============================================================================
// lib/presentation/pages/admin/plantillas/widgets/plantilla_form_paso2_medidas.dart
// ============================================================================
// Paso 2 del form multi-paso de Plantillas — Cuadro de Medidas.
//
// Estructura:
// - Sección "Tallas" con chips multi-select (FilterChip) cargados desde
//   `tallasProvider`.
// - Tabla dinámica de medidas: columnas = tallas seleccionadas, filas =
//   MedidaPunto. Cada fila es un _MedidaRow (StatefulWidget) con sus
//   propios TextEditingControllers (nombre + uno por talla).
// - Botón "+ Agregar punto de medida".
//
// DECISIÓN: cada fila se aísla en su propio StatefulWidget para que
// agregar/quitar tallas o medidas no destruya los controllers de las
// demás filas. La fila reconcilia sus controllers en `didUpdateWidget`
// cuando cambian las tallas: agrega controllers para tallas nuevas y
// dispose los de tallas removidas, conservando los valores ya cargados.
// RAZÓN: si se mantenían los controllers en el padre con una matriz, una
// edición en cualquier celda obligaba a regenerar la matriz entera con
// riesgo de perder foco / cursor.
// CAMBIAR: si se quiere drag-to-reorder de medidas, agregar `key` por
// MedidaPunto.id (ya está) y un ReorderableListView.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/models/medida_punto_model.dart';
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
              Text('Cuadro de medidas', style: AppTypography.h3),
              const SizedBox(height: 2),
              Text(
                'Definí las dimensiones físicas de la prenda en cada talla.',
                style: AppTypography.small.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Caja informativa con el paso a paso. El PDF de Den marca
              // este paso como "clave" y pide texto explicativo extra.
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cómo funciona:',
                      style: AppTypography.small.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      '1. Elegí las tallas en las que se confecciona la '
                      'prenda. Cada talla agrega una columna a la tabla.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '2. Agregá puntos de medida (ej. "Ancho de pecho", '
                      '"Largo de manga") y definí su valor en centímetros '
                      'por cada talla.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '3. Si después deseleccionás una talla, los valores '
                      'cargados para esa talla se descartan.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ─── SELECTOR DE TALLAS ────────────────────────────────────
              _SectionLabel('Tallas'),
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
              const SizedBox(height: AppSpacing.xl),

              // ─── TABLA DE MEDIDAS ──────────────────────────────────────
              if (state.tallasSeleccionadas.isEmpty)
                const _EmptyTallas()
              else
                _TablaMedidas(
                  medidas: state.medidas,
                  // Ordenamos las tallas seleccionadas por su orden en el
                  // catálogo (S, M, L, XL... según id_talla en SQL), no
                  // por orden de selección. El state mantiene el orden de
                  // selección para preservar la intención del usuario.
                  tallasOrdenadas: _ordenarPorCatalogo(
                    state.tallasSeleccionadas,
                    catalogoTallas,
                  ),
                  catalogoTallas: catalogoTallas,
                  onAgregarMedida: notifier.agregarMedida,
                  onRemoverMedida: notifier.removerMedida,
                  onSetNombre: notifier.setNombreMedida,
                  onSetValor: notifier.setValorMedida,
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── HELPERS ────────────────────────────────────────────────────────────────

/// Ordena las tallas seleccionadas según su posición en el catálogo (id
/// del catálogo = orden visual canónico S → XXL, t2 → t6). El state
/// preserva el orden de selección; esto solo afecta la representación.
List<int> _ordenarPorCatalogo(
  List<int> tallasSeleccionadas,
  List<TallaModel> catalogo,
) {
  final copia = [...tallasSeleccionadas];
  copia.sort((a, b) {
    final indexA = catalogo.indexWhere((t) => t.id == a);
    final indexB = catalogo.indexWhere((t) => t.id == b);
    // Tallas no encontradas en catálogo (raro) van al final.
    final ia = indexA == -1 ? 1 << 30 : indexA;
    final ib = indexB == -1 ? 1 << 30 : indexB;
    return ia.compareTo(ib);
  });
  return copia;
}

// ─── SELECTOR DE TALLAS ─────────────────────────────────────────────────────

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

// ─── TABLA DE MEDIDAS — cards apiladas (sin tabla scrollable) ───────────────

/// Renderiza la lista de medidas como una Column de cards apiladas, igual
/// en desktop y mobile. Antes había una tabla scrollable horizontal para
/// desktop y cards para mobile (vía LayoutBuilder); se unificó a cards en
/// todos los tamaños para:
/// - Eliminar el overflow visual al agregar 4+ tallas.
/// - Ser consistente con el estilo de cards read-only del Paso 4 (Resumen).
/// La lógica de controllers / didUpdateWidget de cada `_MedidaRow` se
/// mantiene intacta — solo cambia su representación visual.
class _TablaMedidas extends StatelessWidget {
  const _TablaMedidas({
    required this.medidas,
    required this.tallasOrdenadas,
    required this.catalogoTallas,
    required this.onAgregarMedida,
    required this.onRemoverMedida,
    required this.onSetNombre,
    required this.onSetValor,
  });

  final List<MedidaPunto> medidas;
  // Las tallas ya vienen ordenadas por catálogo (S < M < L < XL...) desde
  // PlantillaFormPaso2Medidas.build via `_ordenarPorCatalogo`.
  final List<int> tallasOrdenadas;
  final List<TallaModel> catalogoTallas;
  final VoidCallback onAgregarMedida;
  final ValueChanged<String> onRemoverMedida;
  final void Function(String idTemp, String nuevoNombre) onSetNombre;
  final void Function(String idTemp, int idTalla, double? valor) onSetValor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionLabel('Puntos de medida (cm)'),
        const SizedBox(height: AppSpacing.sm),
        if (medidas.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.neutral50,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Aún no hay puntos de medida. Apretá "+ Agregar punto de medida".',
              style: AppTypography.small.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
          )
        else
          // Grid responsive: calcula cuántas cards entran según ancho
          // disponible y un mínimo de 280 px por card. Modal desktop
          // ~640px → 2 cards por fila. Mobile <560px → 1 card por fila.
          LayoutBuilder(
            builder: (context, constraints) {
              const minCardWidth = 280.0;
              const spacing = AppSpacing.md;
              final available = constraints.maxWidth;
              final cardsPerRow = (available / minCardWidth)
                  .floor()
                  .clamp(1, 99);
              final cardWidth =
                  (available - spacing * (cardsPerRow - 1)) / cardsPerRow;

              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (var i = 0; i < medidas.length; i++)
                    SizedBox(
                      width: cardWidth,
                      child: _MedidaRow(
                        key: ValueKey('medida-${medidas[i].id}'),
                        medida: medidas[i],
                        tallasSeleccionadas: tallasOrdenadas,
                        catalogoTallas: catalogoTallas,
                        autoFocusNombre:
                            i == medidas.length - 1 &&
                            medidas[i].nombre.isEmpty,
                        onSetNombre: (n) => onSetNombre(medidas[i].id, n),
                        onSetValor: (idTalla, v) =>
                            onSetValor(medidas[i].id, idTalla, v),
                        onRemove: () => onRemoverMedida(medidas[i].id),
                      ),
                    ),
                ],
              );
            },
          ),
        const SizedBox(height: AppSpacing.md),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: onAgregarMedida,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Agregar punto de medida'),
          ),
        ),
      ],
    );
  }
}

// ─── FILA DE MEDIDA ─────────────────────────────────────────────────────────

class _MedidaRow extends StatefulWidget {
  const _MedidaRow({
    super.key,
    required this.medida,
    required this.tallasSeleccionadas,
    required this.catalogoTallas,
    required this.autoFocusNombre,
    required this.onSetNombre,
    required this.onSetValor,
    required this.onRemove,
  });

  final MedidaPunto medida;
  final List<int> tallasSeleccionadas;
  // Necesario para rotular cada talla en la card (una row por talla con
  // nombre + TextField numérico).
  final List<TallaModel> catalogoTallas;
  final bool autoFocusNombre;
  final ValueChanged<String> onSetNombre;
  final void Function(int idTalla, double? valor) onSetValor;
  final VoidCallback onRemove;

  @override
  State<_MedidaRow> createState() => _MedidaRowState();
}

class _MedidaRowState extends State<_MedidaRow> {
  late final TextEditingController _nombreCtrl;
  // Un controller por talla. Se reconcilia en didUpdateWidget cuando cambian
  // las tallas seleccionadas.
  late final Map<int, TextEditingController> _cellCtrls;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.medida.nombre);
    _cellCtrls = {
      for (final id in widget.tallasSeleccionadas)
        id: TextEditingController(
          text: _formatValor(widget.medida.valoresPorTalla[id]),
        ),
    };
  }

  @override
  void didUpdateWidget(covariant _MedidaRow oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reconciliar controllers de celdas cuando cambian las tallas:
    // - Agregar controller para tallas nuevas (con valor del Map).
    // - Disponer controllers de tallas removidas.
    // - Los controllers de tallas que SIGUEN no se tocan (preserva cursor
    //   y texto en edición).
    final nuevas = widget.tallasSeleccionadas.toSet();
    final actuales = _cellCtrls.keys.toSet();

    final aAgregar = nuevas.difference(actuales);
    final aRemover = actuales.difference(nuevas);

    for (final id in aRemover) {
      _cellCtrls[id]?.dispose();
      _cellCtrls.remove(id);
    }
    for (final id in aAgregar) {
      _cellCtrls[id] = TextEditingController(
        text: _formatValor(widget.medida.valoresPorTalla[id]),
      );
    }

    // Si el nombre cambió DESDE AFUERA (raro — solo modo editar inicial),
    // re-sincronizar. Si vino del usuario tipeando, el controller ya está
    // al día y la comparación previene loops.
    if (_nombreCtrl.text != widget.medida.nombre) {
      _nombreCtrl.text = widget.medida.nombre;
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    for (final c in _cellCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _formatValor(double? v) {
    if (v == null) return '';
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toString();
  }

  String _nombreTalla(int id) =>
      widget.catalogoTallas.where((t) => t.id == id).firstOrNull?.nombre ??
      '#$id';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: nombre + papelera
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nombreCtrl,
                  autofocus: widget.autoFocusNombre,
                  style: AppTypography.small.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    hintText: 'Nombre de la medida',
                  ),
                  onChanged: widget.onSetNombre,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: AppColors.error,
                tooltip: 'Eliminar punto de medida',
                onPressed: widget.onRemove,
              ),
            ],
          ),
          const Divider(height: AppSpacing.lg, color: AppColors.border),
          // Una row por talla
          for (final idTalla in widget.tallasSeleccionadas)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 60,
                    child: Text(
                      _nombreTalla(idTalla),
                      style: AppTypography.small.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _cellCtrls[idTalla],
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      textAlign: TextAlign.right,
                      style: AppTypography.small,
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: '—',
                        suffixText: 'cm',
                      ),
                      onChanged: (raw) {
                        if (raw.trim().isEmpty) {
                          widget.onSetValor(idTalla, null);
                          return;
                        }
                        widget.onSetValor(idTalla, double.tryParse(raw));
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── EMPTY STATES ───────────────────────────────────────────────────────────

class _EmptyTallas extends StatelessWidget {
  const _EmptyTallas();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.straighten,
            size: 32,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Seleccioná al menos una talla',
            style: AppTypography.small.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Una vez elegidas las tallas, podrás definir medidas por cada una.',
            style: AppTypography.caption.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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
