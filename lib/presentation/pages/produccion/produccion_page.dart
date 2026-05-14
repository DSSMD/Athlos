// lib/presentation/pages/admin/produccion_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/shared/filter_chips.dart';
import '../../widgets/shared/pagination.dart';
import '../../widgets/shared/sticky_topbar.dart';
import '../../components/produccion/lote_historial_dialog.dart';
import '../../providers/lote_provider.dart'; // 1. Ahora es un ConsumerWidget para poder leer a Riverpod

// TODO: Importar tus providers y modelos reales cuando existan
import '../../../domain/models/lote_model.dart';
// import '../../providers/produccion_provider.dart';

import 'lote_detalle_page.dart'; // Tu vista de detalle
import '../../components/produccion/asignar_trabajador_dialog.dart'; // Modal de asignación

class ProduccionPage extends ConsumerStatefulWidget {
  const ProduccionPage({super.key});

  @override
  ConsumerState<ProduccionPage> createState() => _ProduccionPageState();
}

// TODO: Asegúrate de importar el provider que creamos
// import '../providers/lote_provider.dart';

class _ProduccionPageState extends ConsumerState<ProduccionPage> {
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  static const int _itemsPerPage = 10;
  int _selectedFilter = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 👇 MÉTODOS DEL FRONT MANTENIDOS INTACTOS
  void _abrirDetalle(LoteModel lote) {
    showDialog(
      context: context,
      builder: (context) => LoteDetalleDialog(lote: lote),
    );
  }

  // Busca donde abres el diálogo y cámbialo a esto:
  // En tu produccion_page.dart
  void _abrirAsignacion(LoteModel lote) {
    showDialog(
      context: context,
      builder: (context) => AsignarTrabajadorDialog(lote: lote), // <-- ASÍ
    );
  }

  void _verHistorial(LoteModel lote) {
    showDialog(
      context: context,
      builder: (context) => LoteHistorialDialog(
        loteId: lote.id, // Solo pasamos el ID, el diálogo hará el resto
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    // 👇 1. LLAMAMOS AL BACKEND USANDO RIVERPOD
    final lotesAsync = ref.watch(lotesListProvider);

    return Column(
      children: [
        StickyTopbar(
          isMobile: isMobile,
          title: 'Producción - Lotes',
          searchHint: 'Buscar por Lote ID u Orden...',
          searchController: _searchController,
          onSearchChanged: (value) {
            setState(() => _currentPage = 1);
          },
        ),

        Expanded(
          // 👇 2. ENVOLVEMOS EL CONTENIDO EN EL .WHEN PARA ESPERAR LOS DATOS
          child: lotesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) =>
                Center(child: Text('Error al cargar datos:\n$err')),
            data: (lotesReales) {
              // 👇 3. LÓGICA REAL DE PAGINACIÓN BASADA EN LA BD
              final int totalItems = lotesReales.length;
              final int totalPages = (totalItems > 0)
                  ? (totalItems / _itemsPerPage).ceil()
                  : 1;

              // Cortamos la lista para mostrar solo los 10 de la página actual
              final startIndex = (_currentPage - 1) * _itemsPerPage;
              final endIndex = (startIndex + _itemsPerPage).clamp(
                0,
                totalItems,
              );
              final lotesPaginados = lotesReales.sublist(startIndex, endIndex);

              return SingleChildScrollView(
                padding: EdgeInsets.all(
                  isMobile ? AppSpacing.lg : AppSpacing.xl2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.lg),

                    // 👇 4. PASAMOS LOS LOTES REALES A LA TABLA DEL FRONT
                    _DesktopTableLotes(
                      lotes: lotesPaginados,
                      onView: _abrirDetalle,
                      onAssign: _abrirAsignacion,
                      onHistory: _verHistorial,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Paginación conectada a la BD
                    DesktopPagination(
                      currentPage: _currentPage,
                      totalPages: totalPages,
                      totalItems: totalItems,
                      itemsPerPage: _itemsPerPage,
                      onPageChanged: (page) =>
                          setState(() => _currentPage = page),
                      recordsLabel: 'lotes',
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// DESKTOP TABLE
// ══════════════════════════════════════════════════════════════════════════════

class _DesktopTableLotes extends StatelessWidget {
  // Ahora recibimos la lista de lotes y funciones que aceptan el modelo como parámetro
  final List<LoteModel> lotes;
  final Function(LoteModel) onView;
  final Function(LoteModel) onAssign;
  final Function(LoteModel) onHistory;

  const _DesktopTableLotes({
    required this.lotes,
    required this.onView,
    required this.onAssign,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header de la tabla (Se mantiene fijo) [cite: 19-20]
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                _col('LOTE ID', 2),
                _col('ORDEN', 2),
                _col('ÁREA', 2),
                _col('ESTADO', 2),
                _col('ACCIONES', 2, align: TextAlign.center),
              ],
            ),
          ),

          // Generación dinámica de filas basada en la lista recibida
          if (lotes.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Text('No hay lotes que mostrar'),
            ),

          ...lotes
              .map(
                (lote) => Column(
                  children: [
                    _LoteListRow(
                      lote: lote,
                      onView: () => onView(lote),
                      onAssign: () => onAssign(lote),
                      onHistory: () => onHistory(lote),
                    ),
                    const Divider(height: 1, color: AppColors.border),
                  ],
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  Widget _col(String label, int flex, {TextAlign align = TextAlign.left}) =>
      Expanded(
        flex: flex,
        child: Text(
          label,
          textAlign: align,
          style: AppTypography.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      );
}

// ══════════════════════════════════════════════════════════════════════════════
// LOTE ROW
// ══════════════════════════════════════════════════════════════════════════════
class _LoteListRow extends StatelessWidget {
  final LoteModel
  lote; // Recibe el objeto con todos los datos (orden, cliente, tallas, etc.)
  final VoidCallback onView;
  final VoidCallback onAssign;
  final VoidCallback onHistory;

  const _LoteListRow({
    required this.lote,
    required this.onView,
    required this.onAssign,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // ID del Lote con color primario y peso fuerte
          Expanded(
            flex: 2,
            child: Text(
              // SOLUCIÓN: Acortar el ID para que no rompa la tabla visualmente
              lote.id.length > 8
                  ? lote.id.substring(0, 8).toUpperCase()
                  : lote.id,
              style: AppTypography.small.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary500,
              ),
            ),
          ),

          // Orden con Texto Primario
          Expanded(
            flex: 2,
            child: Text(
              lote.ordenId,
              style: AppTypography.small.copyWith(color: AppColors.textPrimary),
            ),
          ),

          // Área con Texto Secundario (más sutil)
          Expanded(
            flex: 2,
            child: Text(
              lote.areaActual,
              style: AppTypography.small.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),

          // Estado con estilo destacado
          Expanded(
            flex: 2,
            child: Text(
              lote.estado,
              style: AppTypography.small.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          // Acciones: Menú desplegable estilizado
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.center,
              child: PopupMenuButton<String>(
                // Cambiamos el color del icono para que coincida con el estilo clean
                icon: const Icon(
                  Icons.more_horiz,
                  color: AppColors.textSecondary,
                ),
                offset: const Offset(
                  0,
                  40,
                ), // Desplaza el menú hacia abajo para no tapar la fila
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  side: const BorderSide(color: AppColors.border),
                ),
                color: AppColors.brandWhite, // Fondo blanco como tus diálogos
                elevation: 4,
                onSelected: (value) {
                  if (value == 'ver') onView();
                  if (value == 'asignar' || value == 'reasignar') onAssign();
                  if (value == 'historial') onHistory();
                },
                itemBuilder: (context) => [
                  _buildMenuItem(
                    'ver',
                    Icons.visibility_outlined,
                    'Ver detalle',
                  ),
                  _buildMenuItem(
                    'asignar',
                    Icons.person_add_alt_1_outlined,
                    'Asignar trabajador',
                  ),
                  _buildMenuItem(
                    'reasignar',
                    Icons.sync_alt_rounded,
                    'Reasignar',
                  ),
                  _buildMenuItem(
                    'historial',
                    Icons.history_rounded,
                    'Ver historial',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Función auxiliar para que los items del menú se vean profesionales
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
