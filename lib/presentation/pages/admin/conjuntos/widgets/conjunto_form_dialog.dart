// lib/presentation/pages/admin/conjuntos/widgets/conjunto_form_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../../../theme/breakpoints.dart';

import '../../../../../domain/models/conjunto_model.dart';
import '../../../../../domain/models/plantilla_model.dart';
import '../../../../../presentation/providers/conjunto_provider.dart';
import '../../../../../presentation/providers/plantilla_provider.dart';
import '../../../../../presentation/providers/catalogos_provider.dart';
import '../../../../../domain/models/tipo_prenda_model.dart';

class ConjuntoFormDialog extends ConsumerStatefulWidget {
  final ConjuntoModel? conjunto;
  const ConjuntoFormDialog({super.key, this.conjunto});

  @override
  ConsumerState<ConjuntoFormDialog> createState() => _ConjuntoFormDialogState();
}

class _ConjuntoFormDialogState extends ConsumerState<ConjuntoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descripcionCtrl;

  // Lista temporal de plantillas seleccionadas para este conjunto
  late List<ConjuntoPlantillaModel> _seleccionadas;

  bool _guardando = false;
  String? _errorGuardar;

  // ─── Filtro del selector de plantillas ──────────────────────────────────
  String? _categoriaFiltro; // categoría seleccionada (null = todas)
  int? _tipoFiltro; // id_tipo_prenda (null = todos)
  String _busquedaPlantilla = '';

  @override
  void initState() {
    super.initState();
    final c = widget.conjunto;
    _nombreCtrl = TextEditingController(text: c?.nombre ?? '');
    _descripcionCtrl = TextEditingController(text: c?.descripcion ?? '');
    _seleccionadas = c != null ? List.from(c.plantillas) : [];
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  bool get _esEdicion => widget.conjunto != null;

  double get _precioCalculado =>
      _seleccionadas.fold(0.0, (sum, p) => sum + p.subtotal);

  // ─────────────────────────────────────────────── AGREGAR / QUITAR ──

  void _agregarPlantilla(PlantillaModel plantilla) {
    // Si ya está, no duplicar
    if (_seleccionadas.any((s) => s.plantillaId == plantilla.id)) return;
    setState(() {
      _seleccionadas.add(
        ConjuntoPlantillaModel(
          id: '',
          conjuntoId: widget.conjunto?.id ?? '',
          plantillaId: plantilla.id,
          nombrePlantilla: plantilla.nombre,
          cantidad: 1,
          precioPlantilla: plantilla.precioPlantilla,
        ),
      );
    });
  }

  void _quitarPlantilla(int index) {
    setState(() => _seleccionadas.removeAt(index));
  }

  void _cambiarCantidad(int index, int nuevaCantidad) {
    if (nuevaCantidad < 1) return;
    setState(() {
      _seleccionadas[index] = _seleccionadas[index].copyWith(
        cantidad: nuevaCantidad,
      );
    });
  }

  // ───────────────────────────────────────────────────────── GUARDAR ──

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_seleccionadas.isEmpty) {
      setState(() => _errorGuardar = 'Agrega al menos una plantilla.');
      return;
    }

    setState(() {
      _guardando = true;
      _errorGuardar = null;
    });

    try {
      final notifier = ref.read(conjuntoProvider.notifier);
      if (_esEdicion) {
        await notifier.actualizarConjunto(
          id: widget.conjunto!.id,
          nombre: _nombreCtrl.text,
          descripcion: _descripcionCtrl.text,
          plantillas: _seleccionadas,
        );
      } else {
        await notifier.crearConjunto(
          nombre: _nombreCtrl.text,
          descripcion: _descripcionCtrl.text,
          plantillas: _seleccionadas,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _guardando = false;
        _errorGuardar = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // ───────────────────────────────────────────────────────────── BUILD ──

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    return Dialog(
      backgroundColor: AppColors.brandWhite,
      insetPadding: isMobile
          ? const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.md,
            )
          : const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isMobile ? 550 : 780,
          maxHeight: isMobile ? 850 : 820,
        ),
        child: Padding(
          padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.xl2),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Cabecera ──
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _esEdicion ? 'Editar Conjunto' : 'Nuevo Conjunto',
                        style: AppTypography.h3.copyWith(
                          fontSize: isMobile ? 18 : null,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
                const Divider(height: AppSpacing.xl),

                Expanded(
                  child: isMobile
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Panel izquierdo: datos + plantillas seleccionadas ──
                            Expanded(
                              flex: 5,
                              child: _PanelIzquierdo(
                                nombreCtrl: _nombreCtrl,
                                descripcionCtrl: _descripcionCtrl,
                                seleccionadas: _seleccionadas,
                                precioCalculado: _precioCalculado,
                                errorGuardar: _errorGuardar,
                                onQuitarPlantilla: _quitarPlantilla,
                                onCambiarCantidad: _cambiarCantidad,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            const Divider(height: 1),
                            const SizedBox(height: AppSpacing.lg),
                            // ── Panel derecho: selector de plantillas ──
                            Expanded(
                              flex: 6,
                              child: _PanelSelectorPlantillas(
                                categoriaFiltro: _categoriaFiltro,
                                tipoFiltro: _tipoFiltro,
                                busqueda: _busquedaPlantilla,
                                seleccionadasIds: _seleccionadas
                                    .map((s) => s.plantillaId)
                                    .toSet(),
                                onCategoriaChanged: (cat) => setState(() {
                                  _categoriaFiltro = cat;
                                  _tipoFiltro = null;
                                }),
                                onTipoChanged: (id) =>
                                    setState(() => _tipoFiltro = id),
                                onBusquedaChanged: (q) =>
                                    setState(() => _busquedaPlantilla = q),
                                onAgregarPlantilla: _agregarPlantilla,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Panel izquierdo: datos + plantillas seleccionadas ──
                            Expanded(
                              flex: 5,
                              child: _PanelIzquierdo(
                                nombreCtrl: _nombreCtrl,
                                descripcionCtrl: _descripcionCtrl,
                                seleccionadas: _seleccionadas,
                                precioCalculado: _precioCalculado,
                                errorGuardar: _errorGuardar,
                                onQuitarPlantilla: _quitarPlantilla,
                                onCambiarCantidad: _cambiarCantidad,
                              ),
                            ),

                            const SizedBox(width: AppSpacing.xl),
                            const VerticalDivider(width: 1),
                            const SizedBox(width: AppSpacing.xl),

                            // ── Panel derecho: selector de plantillas ──
                            Expanded(
                              flex: 4,
                              child: _PanelSelectorPlantillas(
                                categoriaFiltro: _categoriaFiltro,
                                tipoFiltro: _tipoFiltro,
                                busqueda: _busquedaPlantilla,
                                seleccionadasIds: _seleccionadas
                                    .map((s) => s.plantillaId)
                                    .toSet(),
                                onCategoriaChanged: (cat) => setState(() {
                                  _categoriaFiltro = cat;
                                  _tipoFiltro = null;
                                }),
                                onTipoChanged: (id) =>
                                    setState(() => _tipoFiltro = id),
                                onBusquedaChanged: (q) =>
                                    setState(() => _busquedaPlantilla = q),
                                onAgregarPlantilla: _agregarPlantilla,
                              ),
                            ),
                          ],
                        ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // ── Botones ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _guardando
                          ? null
                          : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                      style: TextButton.styleFrom(foregroundColor: AppColors.primary500),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary500,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.md,
                        ),
                      ),
                      onPressed: _guardando ? null : _guardar,
                      child: _guardando
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _esEdicion ? 'Guardar cambios' : 'Crear Conjunto',
                              style: const TextStyle(color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════ PANEL IZQUIERDO ══

class _PanelIzquierdo extends StatelessWidget {
  const _PanelIzquierdo({
    required this.nombreCtrl,
    required this.descripcionCtrl,
    required this.seleccionadas,
    required this.precioCalculado,
    required this.errorGuardar,
    required this.onQuitarPlantilla,
    required this.onCambiarCantidad,
  });

  final TextEditingController nombreCtrl;
  final TextEditingController descripcionCtrl;
  final List<ConjuntoPlantillaModel> seleccionadas;
  final double precioCalculado;
  final String? errorGuardar;
  final void Function(int) onQuitarPlantilla;
  final void Function(int, int) onCambiarCantidad;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nombre
        TextFormField(
          controller: nombreCtrl,
          decoration: const InputDecoration(
            labelText: 'Nombre del Conjunto *',
            border: OutlineInputBorder(),
          ),
          validator: (v) =>
              (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
        ),
        const SizedBox(height: AppSpacing.md),

        // Descripción
        TextFormField(
          controller: descripcionCtrl,
          decoration: const InputDecoration(
            labelText: 'Descripción',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: AppSpacing.lg),

        // Etiqueta plantillas
        Text(
          'PLANTILLAS INCLUIDAS (${seleccionadas.length})',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Error
        if (errorGuardar != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              errorGuardar!,
              style: AppTypography.small.copyWith(color: Colors.red),
            ),
          ),

        // Lista de plantillas seleccionadas
        Expanded(
          child: seleccionadas.isEmpty
              ? Center(
                  child: Text(
                    'Sin plantillas.\nSelecciona del panel derecho.',
                    textAlign: TextAlign.center,
                    style: AppTypography.small.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: seleccionadas.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final item = seleccionadas[i];
                    return _ItemSeleccionado(
                      item: item,
                      onQuitar: () => onQuitarPlantilla(i),
                      onCambiarCantidad: (val) => onCambiarCantidad(i, val),
                    );
                  },
                ),
        ),

        const Divider(height: AppSpacing.xl),

        // Precio total calculado
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Precio total calculado',
              style: AppTypography.small.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              'Bs. ${precioCalculado.toStringAsFixed(2)}',
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── Ítem de plantilla seleccionada ──────────────────────────────────────────

class _ItemSeleccionado extends StatelessWidget {
  const _ItemSeleccionado({
    required this.item,
    required this.onQuitar,
    required this.onCambiarCantidad,
  });

  final ConjuntoPlantillaModel item;
  final VoidCallback onQuitar;
  final void Function(int) onCambiarCantidad;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nombrePlantilla,
                  style: AppTypography.small.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${item.precioPlantilla.toStringAsFixed(2)} Bs. c/u',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          // Control de cantidad
          Row(
            children: [
              _CantidadBtn(
                icon: Icons.remove,
                onTap: () => onCambiarCantidad(item.cantidad - 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '${item.cantidad}',
                  style: AppTypography.small.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _CantidadBtn(
                icon: Icons.add,
                onTap: () => onCambiarCantidad(item.cantidad + 1),
              ),
            ],
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'Bs. ${item.subtotal.toStringAsFixed(2)}',
            style: AppTypography.small.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Colors.red),
            onPressed: onQuitar,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          ),
        ],
      ),
    );
  }
}

class _CantidadBtn extends StatelessWidget {
  const _CantidadBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(icon, size: 14, color: AppColors.textSecondary),
      ),
    );
  }
}

// ══════════════════════════════════════════ PANEL SELECTOR DE PLANTILLAS ══

class _PanelSelectorPlantillas extends ConsumerWidget {
  const _PanelSelectorPlantillas({
    required this.categoriaFiltro,
    required this.tipoFiltro,
    required this.busqueda,
    required this.seleccionadasIds,
    required this.onCategoriaChanged,
    required this.onTipoChanged,
    required this.onBusquedaChanged,
    required this.onAgregarPlantilla,
  });

  final String? categoriaFiltro;
  final int? tipoFiltro;
  final String busqueda;
  final Set<String> seleccionadasIds;
  final void Function(String?) onCategoriaChanged;
  final void Function(int?) onTipoChanged;
  final void Function(String) onBusquedaChanged;
  final void Function(PlantillaModel) onAgregarPlantilla;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiposAsync = ref.watch(tiposPrendaProvider);
    final categoriasAsync = tiposAsync.whenData(
      (tipos) => tipos.map((t) => t.categoria).toSet().toList()..sort(),
    );
    final plantillasAsync = ref.watch(plantillaProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AGREGAR PLANTILLA',
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Filtro por categoría ──
        categoriasAsync.when(
          data: (cats) => DropdownButtonFormField<String?>(
            initialValue: categoriaFiltro,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Categoría',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Todas')),
              ...cats.map((c) => DropdownMenuItem(value: c, child: Text(c))),
            ],
            onChanged: onCategoriaChanged,
          ),
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.sm),

        // ── Filtro por tipo de prenda ──
        tiposAsync.when(
          data: (tipos) {
            final filtrados = categoriaFiltro != null
                ? tipos.where((t) => t.categoria == categoriaFiltro).toList()
                : tipos;
            return DropdownButtonFormField<int?>(
              initialValue: tipoFiltro,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Tipo de prenda',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Todos')),
                ...filtrados.map(
                  (t) => DropdownMenuItem(value: t.id, child: Text(t.nombre)),
                ),
              ],
              onChanged: onTipoChanged,
            );
          },
          loading: () => const LinearProgressIndicator(),
          error: (_, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: AppSpacing.sm),

        // ── Búsqueda por nombre ──
        TextField(
          decoration: const InputDecoration(
            labelText: 'Buscar plantilla',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search, size: 18),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          onChanged: onBusquedaChanged,
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Lista de plantillas disponibles ──
        Expanded(
          child: plantillasAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                'Error al cargar plantillas',
                style: AppTypography.small.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            data: (todas) {
              // Aplicar filtros
              var lista = todas.where((p) => p.activa).toList();
              if (tipoFiltro != null) {
                lista = lista
                    .where((p) => p.idTipoPrenda == tipoFiltro)
                    .toList();
              }
              if (busqueda.isNotEmpty) {
                final q = busqueda.toLowerCase();
                lista = lista
                    .where((p) => p.nombre.toLowerCase().contains(q))
                    .toList();
              }

              if (lista.isEmpty) {
                return Center(
                  child: Text(
                    'No hay plantillas disponibles',
                    style: AppTypography.small.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                );
              }

              // Agrupar por tipo si hay tipos cargados
              return tiposAsync.when(
                data: (tipos) => _ListaAgrupada(
                  plantillas: lista,
                  tipos: tipos,
                  seleccionadasIds: seleccionadasIds,
                  onAgregar: onAgregarPlantilla,
                ),
                loading: () => _ListaPlana(
                  plantillas: lista,
                  seleccionadasIds: seleccionadasIds,
                  onAgregar: onAgregarPlantilla,
                ),
                error: (_, _) => _ListaPlana(
                  plantillas: lista,
                  seleccionadasIds: seleccionadasIds,
                  onAgregar: onAgregarPlantilla,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Lista agrupada por tipo de prenda ───────────────────────────────────────

class _ListaAgrupada extends StatelessWidget {
  const _ListaAgrupada({
    required this.plantillas,
    required this.tipos,
    required this.seleccionadasIds,
    required this.onAgregar,
  });

  final List<PlantillaModel> plantillas;
  final List<TipoPrendaModel> tipos;
  final Set<String> seleccionadasIds;
  final void Function(PlantillaModel) onAgregar;

  @override
  Widget build(BuildContext context) {
    // Agrupar: Map<idTipoPrenda, List<PlantillaModel>>
    final Map<int, List<PlantillaModel>> grupos = {};
    for (final p in plantillas) {
      grupos.putIfAbsent(p.idTipoPrenda, () => []).add(p);
    }

    // Orden: mismo que el catálogo (ya viene ordenado por categoria + nombre)
    final idsOrdenados = tipos
        .map((t) => t.id)
        .where((id) => grupos.containsKey(id))
        .toList();

    return ListView.builder(
      itemCount: idsOrdenados.length,
      itemBuilder: (context, i) {
        final idTipo = idsOrdenados[i];
        final tipo = tipos.firstWhere((t) => t.id == idTipo);
        final items = grupos[idTipo]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header de categoría → tipo
            Padding(
              padding: const EdgeInsets.fromLTRB(0, AppSpacing.sm, 0, 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary500.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tipo.categoria.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        fontSize: 9,
                        color: AppColors.primary500,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tipo.nombre,
                      style: AppTypography.small.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            ...items.map(
              (p) => _PlantillaOpcion(
                plantilla: p,
                yaAgregada: seleccionadasIds.contains(p.id),
                onAgregar: () => onAgregar(p),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Lista plana (fallback) ───────────────────────────────────────────────────

class _ListaPlana extends StatelessWidget {
  const _ListaPlana({
    required this.plantillas,
    required this.seleccionadasIds,
    required this.onAgregar,
  });

  final List<PlantillaModel> plantillas;
  final Set<String> seleccionadasIds;
  final void Function(PlantillaModel) onAgregar;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: plantillas.length,
      itemBuilder: (context, i) => _PlantillaOpcion(
        plantilla: plantillas[i],
        yaAgregada: seleccionadasIds.contains(plantillas[i].id),
        onAgregar: () => onAgregar(plantillas[i]),
      ),
    );
  }
}

// ─── Fila de plantilla disponible ────────────────────────────────────────────

class _PlantillaOpcion extends StatelessWidget {
  const _PlantillaOpcion({
    required this.plantilla,
    required this.yaAgregada,
    required this.onAgregar,
  });

  final PlantillaModel plantilla;
  final bool yaAgregada;
  final VoidCallback onAgregar;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: yaAgregada ? null : onAgregar,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plantilla.nombre,
                    style: AppTypography.small.copyWith(
                      color: yaAgregada
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Bs. ${plantilla.precioPlantilla.toStringAsFixed(2)}',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            yaAgregada
                ? const Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: AppColors.success,
                  )
                : IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      size: 18,
                      color: AppColors.primary500,
                    ),
                    onPressed: onAgregar,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 28,
                      minHeight: 28,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
