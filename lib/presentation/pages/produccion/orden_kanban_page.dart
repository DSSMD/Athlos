// lib/presentation/pages/admin/orden_kanban_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../../domain/models/lote_model.dart';
import '../../providers/lote_provider.dart';

// Importa tus modales
import 'lote_detalle_page.dart';
import '../../components/produccion/asignar_trabajador_dialog.dart';
import '../../components/produccion/lote_historial_dialog.dart';

class OrdenKanbanPage extends ConsumerStatefulWidget {
  final String ordenId;
  final String cliente;
  final List<LoteModel> lotes;

  const OrdenKanbanPage({
    super.key,
    required this.ordenId,
    required this.cliente,
    required this.lotes,
  });

  @override
  ConsumerState<OrdenKanbanPage> createState() => _OrdenKanbanPageState();
}

class _OrdenKanbanPageState extends ConsumerState<OrdenKanbanPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _abrirDetalle(LoteModel lote) {
    showDialog(
      context: context,
      builder: (context) => LoteDetalleDialog(lote: lote),
    );
  }

  void _abrirAsignacion(LoteModel lote) async {
    final seAsignoEfectivamente = await showDialog<bool>(
      context: context,
      builder: (context) => AsignarTrabajadorDialog(lote: lote),
    );

    if (seAsignoEfectivamente == true) {
      ref.invalidate(lotesListProvider);
    }
  }

  void _verHistorial(LoteModel lote) {
    showDialog(
      context: context,
      builder: (context) => LoteHistorialDialog(loteId: lote.id),
    );
  }

  void _verAvance(LoteModel lote) {
    showDialog(
      context: context,
      builder: (context) => LoteAvanceDialog(lote: lote),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final double columnWidth = isMobile
        ? MediaQuery.of(context).size.width * 0.85
        : 320.0;

    final List<String> columnasEstados = [
      'Pendiente',
      'En Corte',
      'Listo para Sublimado',
      'En Sublimado',
      'Listo para Confección',
      'En Confección',
      'Terminado',
    ];

    final lotesAsync = ref.watch(lotesListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.brandWhite,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tablero: ${widget.ordenId.length > 8 ? widget.ordenId.substring(0, 8).toUpperCase() : widget.ordenId.toUpperCase()}',
              style: AppTypography.body.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              'Cliente: ${widget.cliente}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        elevation: 1,
      ),
      body: lotesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error al cargar datos:\n$err')),
        data: (todosLosLotesDeLaBD) {
          final lotesDeEstaOrden = todosLosLotesDeLaBD
              .where((l) => l.ordenId == widget.ordenId)
              .toList();

          return ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.trackpad,
              },
            ),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              trackVisibility: true,
              thickness: 8.0,
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(
                  left: AppSpacing.lg,
                  right: AppSpacing.lg,
                  top: AppSpacing.lg,
                  bottom: AppSpacing.xl2,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: columnasEstados.map((estadoStr) {
                    final lotesColumna = lotesDeEstaOrden
                        .where((l) => l.estado == estadoStr)
                        .toList();
                    return _KanbanColumn(
                      title: estadoStr,
                      lotes: lotesColumna,
                      width: columnWidth,
                      onView: _abrirDetalle,
                      onAssign: _abrirAsignacion,
                      onHistory: _verHistorial,
                      onProgress: _verAvance,
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// COLUMNA KANBAN
// ══════════════════════════════════════════════════════════════════════════════
class _KanbanColumn extends StatelessWidget {
  final String title;
  final List<LoteModel> lotes;
  final double width;
  final Function(LoteModel) onView;
  final Function(LoteModel) onAssign;
  final Function(LoteModel) onHistory;
  final Function(LoteModel) onProgress;

  const _KanbanColumn({
    required this.title,
    required this.lotes,
    required this.width,
    required this.onView,
    required this.onAssign,
    required this.onHistory,
    required this.onProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: const EdgeInsets.only(right: AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: AppTypography.small.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary500.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${lotes.length}',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              itemCount: lotes.length,
              itemBuilder: (context, index) => _KanbanCard(
                lote: lotes[index],
                onView: () => onView(lotes[index]),
                onAssign: () => onAssign(lotes[index]),
                onHistory: () => onHistory(lotes[index]),
                onProgress: () => onProgress(lotes[index]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TARJETA KANBAN (Con lógica de bloqueo de botón "Asignar")
// ══════════════════════════════════════════════════════════════════════════════
class _KanbanCard extends StatelessWidget {
  final LoteModel lote;
  final VoidCallback onView, onAssign, onHistory, onProgress;

  const _KanbanCard({
    required this.lote,
    required this.onView,
    required this.onAssign,
    required this.onHistory,
    required this.onProgress,
  });

  @override
  Widget build(BuildContext context) {
    Color barColor = AppColors.primary500;
    if (lote.estado == 'Terminado') barColor = Colors.green;
    if (lote.estado == 'Pendiente') barColor = Colors.orange;

    bool puedeAsignar =
        lote.estado == 'Pendiente' ||
        lote.estado == 'Listo para Sublimado' ||
        lote.estado == 'Listo para Confección';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: barColor, width: 4)),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'LOTE: ${lote.id.length > 8 ? lote.id.substring(0, 8).toUpperCase() : lote.id}',
                    style: AppTypography.small.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(
                  height: 24,
                  width: 24,
                  child: PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_horiz, size: 20),
                    onSelected: (val) {
                      if (val == 'historial') onHistory();
                    },
                    itemBuilder: (_) => [
                      _buildMenuItem(
                        'historial',
                        Icons.history_rounded,
                        'Ver historial',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Prenda: ${lote.prenda}', style: AppTypography.caption),
            Text(
              'Tallas: ${lote.tallas.join(", ")}',
              style: AppTypography.caption,
            ),
            Text('Cant: ${lote.cantidad}', style: AppTypography.caption),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onView,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: barColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: const Text(
                      'Ver Detalle',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                Expanded(
                  child: OutlinedButton(
                    onPressed: puedeAsignar ? onAssign : null,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: puedeAsignar ? barColor : Colors.grey.shade300,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      // 💡 CORREGIDO: Eliminado el error 'maybeText:' fantasma
                      puedeAsignar
                          ? 'Asignar'
                          : (lote.estado == 'Terminado'
                                ? 'Finalizado'
                                : 'En proceso'),
                      style: TextStyle(
                        fontSize: 11,
                        color: puedeAsignar ? barColor : Colors.grey.shade400,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildMenuItem(
    String value,
    IconData icon,
    String label,
  ) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          Text(
            label,
            style: AppTypography.small.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DIÁLOGO DE AVANCE
// ══════════════════════════════════════════════════════════════════════════════
class LoteAvanceDialog extends StatelessWidget {
  final LoteModel lote;
  const LoteAvanceDialog({super.key, required this.lote});

  @override
  Widget build(BuildContext context) {
    final List<String> estadosProduccion = [
      'Pendiente',
      'En Corte',
      'Listo para Sublimado',
      'En Sublimado',
      'Listo para Confección',
      'En Confección',
      'Terminado',
    ];
    int pasoActual = estadosProduccion.indexOf(lote.estado);
    if (pasoActual == -1) pasoActual = 0;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Avance del Lote', style: AppTypography.h3),
              const SizedBox(height: AppSpacing.lg),
              ...List.generate(estadosProduccion.length, (index) {
                final completado = index < pasoActual;
                final activo = index == pasoActual;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Icon(
                          completado
                              ? Icons.check_circle
                              : (activo
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked),
                          color: completado
                              ? Colors.green
                              : (activo ? AppColors.primary500 : Colors.grey),
                        ),
                        if (index != estadosProduccion.length - 1)
                          Container(
                            width: 2,
                            height: 25,
                            color: completado
                                ? Colors.green
                                : Colors.grey.shade300,
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Text(
                      estadosProduccion[index],
                      style: TextStyle(
                        fontWeight: activo
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: activo ? AppColors.primary500 : Colors.black87,
                      ),
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
