// lib/presentation/pages/admin/produccion_page.dart

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/shared/pagination.dart';
import '../../widgets/shared/sticky_topbar.dart';
import '../../widgets/shared/mobile_screen_header.dart';
import '../../widgets/shared/search_input.dart';
import '../../providers/lote_provider.dart';
import '../../../domain/models/lote_model.dart';

// Importamos la nueva pantalla que crearemos en el paso 2
import 'orden_kanban_page.dart';
import 'scheduling/scheduling_page.dart';
import '../../providers/scheduling_provider.dart';

class ProduccionPage extends ConsumerStatefulWidget {
  const ProduccionPage({super.key});

  @override
  ConsumerState<ProduccionPage> createState() => _ProduccionPageState();
}

class _ProduccionPageState extends ConsumerState<ProduccionPage> {
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  String _obtenerNombreEstadoOrden(int? id) {
    switch (id) {
      case 1:
        return 'Pendiente';
      case 2:
        return 'En Producción';
      case 3:
        return 'Finalizada';
      case 4:
        return 'Entregada';
      default:
        return 'Desconocido';
    }
  }

  Color _obtenerColorEstadoOrden(int? id) {
    switch (id) {
      case 1:
        return Colors.orange;
      case 2:
        return AppColors.primary500;
      case 3:
        return Colors.green;
      case 4:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final lotesAsync = ref.watch(lotesListProvider);
    final ordenesEnRiesgo = ref.watch(ordenesEnRiesgoCountProvider);

    return Column(
      children: [
        if (isMobile)
          MobileScreenHeader(
            title: 'Directorio de Órdenes',
            trailing: _SchedulingButton(
              count: ordenesEnRiesgo,
              onPressed: () => _abrirScheduling(context),
            ),
            bottom: SearchInput(
              hintText: 'Buscar por orden o cliente...',
              controller: _searchController,
              onChanged: (value) => setState(() => _currentPage = 1),
            ),
          )
        else
          StickyTopbar(
            title: 'Directorio de Órdenes',
            searchHint: 'Buscar por Orden o Cliente...',
            searchController: _searchController,
            onSearchChanged: (value) => setState(() => _currentPage = 1),
            actionWidget: _SchedulingButton(
              count: ordenesEnRiesgo,
              onPressed: () => _abrirScheduling(context),
            ),
          ),
        Expanded(
          child: lotesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => Center(child: Text('Error: $err')),
            data: (lotesReales) {
              // Filtro de búsqueda
              final query = _searchController.text.toLowerCase();
              final lotesFiltrados = query.isEmpty
                  ? lotesReales
                  : lotesReales
                        .where(
                          (l) =>
                              l.ordenId.toLowerCase().contains(query) ||
                              l.cliente.toLowerCase().contains(query),
                        )
                        .toList();

              // Agrupamos por orden
              final Map<String, List<LoteModel>> lotesPorOrden = {};
              for (var lote in lotesFiltrados) {
                if (!lotesPorOrden.containsKey(lote.ordenId)) {
                  lotesPorOrden[lote.ordenId] = [];
                }
                lotesPorOrden[lote.ordenId]!.add(lote);
              }

              final List<String> ordenesUnicas = lotesPorOrden.keys.toList();
              // Ordenar por fecha_orden descendente (la más reciente primero)
              ordenesUnicas.sort((a, b) {
                final dateA = lotesPorOrden[a]?.first.fechaOrden ?? DateTime(1970);
                final dateB = lotesPorOrden[b]?.first.fechaOrden ?? DateTime(1970);
                return dateB.compareTo(dateA);
              });

              final int totalItems = ordenesUnicas.length;
              final int totalPages = (totalItems > 0)
                  ? (totalItems / _itemsPerPage).ceil()
                  : 1;

              final startIndex = (_currentPage - 1) * _itemsPerPage;
              final endIndex = (startIndex + _itemsPerPage).clamp(
                0,
                totalItems,
              );
              final ordenesPaginadas = ordenesUnicas.sublist(
                startIndex,
                endIndex,
              );

              return SingleChildScrollView(
                padding: EdgeInsets.all(
                  isMobile ? AppSpacing.lg : AppSpacing.xl2,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (ordenesPaginadas.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.xl2),
                          child: Text('No hay órdenes encontradas.'),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: ordenesPaginadas.length,
                        itemBuilder: (context, index) {
                          final ordenId = ordenesPaginadas[index];
                          final lotesDeEstaOrden = lotesPorOrden[ordenId]!;
                          final cliente = lotesDeEstaOrden.first.cliente;

                          abrirKanban() {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrdenKanbanPage(
                                  ordenId: ordenId,
                                  cliente: cliente,
                                  lotes: lotesDeEstaOrden,
                                ),
                              ),
                            );
                          }

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: isMobile
                                ? InkWell(
                                    onTap: abrirKanban,
                                    borderRadius: BorderRadius.circular(AppRadius.lg),
                                    child: Padding(
                                      padding: const EdgeInsets.all(AppSpacing.md),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Orden: ${ordenId.length > 8 ? ordenId.substring(0, 8).toUpperCase() : ordenId.toUpperCase()}',
                                                style: AppTypography.body.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              if (lotesDeEstaOrden.first.idEstadoOrden != null)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: _obtenerColorEstadoOrden(
                                                      lotesDeEstaOrden.first.idEstadoOrden,
                                                    ).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: _obtenerColorEstadoOrden(
                                                        lotesDeEstaOrden.first.idEstadoOrden,
                                                      ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    _obtenerNombreEstadoOrden(
                                                      lotesDeEstaOrden.first.idEstadoOrden,
                                                    ),
                                                    style: AppTypography.caption.copyWith(
                                                      color: _obtenerColorEstadoOrden(
                                                        lotesDeEstaOrden.first.idEstadoOrden,
                                                      ),
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: AppSpacing.sm),
                                          Text(
                                            'Cliente: $cliente',
                                            style: AppTypography.body,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${lotesDeEstaOrden.length} Lotes activos',
                                            style: AppTypography.small.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                          if (lotesDeEstaOrden.first.fechaOrden != null) ...[
                                            const SizedBox(height: AppSpacing.xs),
                                            Text(
                                              'Creada: ${DateFormat('dd/MM/yyyy HH:mm').format(lotesDeEstaOrden.first.fechaOrden!.toLocal())}',
                                              style: AppTypography.caption.copyWith(
                                                color: AppColors.primary500,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: AppSpacing.md),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: abrirKanban,
                                              icon: const Icon(Icons.view_kanban, size: 18),
                                              label: const Text('Ver Tablero'),
                                              style: ElevatedButton.styleFrom(
                                                elevation: 0,
                                                foregroundColor: Colors.white,
                                                backgroundColor: AppColors.primary500,
                                                padding: const EdgeInsets.symmetric(
                                                  vertical: AppSpacing.sm,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListTile(
                                    contentPadding: const EdgeInsets.all(
                                      AppSpacing.lg,
                                    ),
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.primary500
                                          .withOpacity(0.1),
                                      child: const Icon(
                                        Icons.inventory_2_outlined,
                                        color: AppColors.primary500,
                                      ),
                                    ),
                                    title: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Orden: ${ordenId.length > 8 ? ordenId.substring(0, 8).toUpperCase() : ordenId.toUpperCase()}',
                                          style: AppTypography.body.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (lotesDeEstaOrden.first.idEstadoOrden != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _obtenerColorEstadoOrden(
                                                lotesDeEstaOrden.first.idEstadoOrden,
                                              ).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: _obtenerColorEstadoOrden(
                                                  lotesDeEstaOrden.first.idEstadoOrden,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              _obtenerNombreEstadoOrden(
                                                lotesDeEstaOrden.first.idEstadoOrden,
                                              ),
                                              style: AppTypography.caption.copyWith(
                                                color: _obtenerColorEstadoOrden(
                                                  lotesDeEstaOrden.first.idEstadoOrden,
                                                ),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text(
                                          'Cliente: $cliente • ${lotesDeEstaOrden.length} Lotes activos',
                                        ),
                                        if (lotesDeEstaOrden.first.fechaOrden != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            'Creada: ${DateFormat('dd/MM/yyyy HH:mm').format(lotesDeEstaOrden.first.fechaOrden!.toLocal())}',
                                            style: AppTypography.caption.copyWith(
                                              color: AppColors.primary500,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    trailing: ElevatedButton.icon(
                                      onPressed: abrirKanban,
                                      icon: const Icon(Icons.view_kanban, size: 18),
                                      label: const Text('Ver Tablero'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary500,
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ),
                          );
                        },
                      ),

                    const SizedBox(height: AppSpacing.xl),
                    DesktopPagination(
                      currentPage: _currentPage,
                      totalPages: totalPages,
                      totalItems: totalItems,
                      itemsPerPage: _itemsPerPage,
                      onPageChanged: (page) =>
                          setState(() => _currentPage = page),
                      recordsLabel: 'órdenes',
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

  void _abrirScheduling(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    if (isMobile) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SchedulingPage()),
      );
    } else {
      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900, maxHeight: 700),
            child: const SchedulingPage(),
          ),
        ),
      );
    }
  }
}

// ────────────────────────────────────────────────────────────────────────────
// BOTÓN DE SCHEDULING CON BADGE
// ────────────────────────────────────────────────────────────────────────────

class _SchedulingButton extends StatelessWidget {
  const _SchedulingButton({required this.count, required this.onPressed});
  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.schedule_outlined, size: 18),
          label: const Text('Scheduling'),
          style: OutlinedButton.styleFrom(
            foregroundColor: count > 0 ? AppColors.error : AppColors.primary500,
            side: BorderSide(
              color: count > 0
                  ? AppColors.error.withValues(alpha: 0.5)
                  : AppColors.border,
            ),
          ),
        ),
        if (count > 0)
          Positioned(
            top: -6,
            right: -6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.error,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: AppTypography.caption.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
