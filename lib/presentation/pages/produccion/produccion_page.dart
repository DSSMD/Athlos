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

class _ProduccionPageState extends ConsumerState<ProduccionPage> {
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  // 0: Todos, 1: Corte, 2: Costura, 3: Acabado
  int _selectedFilter = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // TODO: BACKEND - Cambiar por ref.watch(produccionProvider)
  // He añadido un elemento mock para que puedas probar la funcionalidad de los botones inmediatamente
  final List<LoteModel> _lotesMock = [
    LoteModel(
      id: '#LT-2045',
      ordenId: '#ORD-889',
      cliente: 'Textiles Athlos',
      prenda: 'Camiseta Deportiva',
      tallas: ['S', 'M', 'L'],
      cantidad: 150,
      areaActual: 'CORTE',
      estado: 'En Proceso',
    ),
  ];

  void _abrirDetalle(LoteModel lote) {
    showDialog(
      context: context,
      builder: (context) => LoteDetalleDialog(lote: lote),
    );
  }

  // Ajustado para que coincida con la firma que espera el Widget de la tabla
  void _abrirAsignacion(LoteModel lote) {
    showDialog(
      context: context,
      builder: (context) => AsignarTrabajadorDialog(
        // Punto 3: El área actual filtra los trabajadores en el backend
        areaActual: lote.areaActual,
        loteId: lote.id,
      ),
    );
  }

  void _verHistorial(LoteModel lote) {
    showDialog(
      context: context,
      builder: (context) => LoteHistorialDialog(
        loteId: lote.id,
        historial:
            const [], // Enviamos lista vacía para ver el mensaje "No hay historial"
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final int totalItems = _lotesMock.length;
    final int totalPages = (totalItems / _itemsPerPage).ceil().clamp(1, 999);
    return Column(
      children: [
        StickyTopbar(
          isMobile: isMobile,
          title: 'Producción - Lotes',
          searchHint: 'Buscar por Lote ID u Orden...',
          searchController: _searchController,
          onSearchChanged: (value) {
            // TODO: BACKEND - Trigger de búsqueda filtrada
            setState(() => _currentPage = 1);
          },
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.lg),

                // Tabla Desktop Corregida
                _DesktopTableLotes(
                  lotes: _lotesMock, // Pasamos la lista de datos
                  onView: _abrirDetalle, // Conectamos Ver Detalle
                  onAssign: _abrirAsignacion, // Conectamos Asignar/Reasignar
                  onHistory: _verHistorial, // Conectamos Ver Historial
                ),

                const SizedBox(height: AppSpacing.xl),

                // Paginación
                DesktopPagination(
                  currentPage: _currentPage,
                  totalPages: totalPages,
                  totalItems:
                      totalItems, // Corregido: muestra la cantidad real de la lista
                  itemsPerPage: _itemsPerPage,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  recordsLabel: 'lotes',
                ),
              ],
            ),
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
              lote.id,
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
