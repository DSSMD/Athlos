// lib/presentation/pages/admin/produccion_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/shared/pagination.dart';
import '../../widgets/shared/sticky_topbar.dart';
import '../../providers/lote_provider.dart';
import '../../../domain/models/lote_model.dart';

// Importamos la nueva pantalla que crearemos en el paso 2
import 'orden_kanban_page.dart';

class ProduccionPage extends ConsumerStatefulWidget {
  const ProduccionPage({super.key});

  @override
  ConsumerState<ProduccionPage> createState() => _ProduccionPageState();
}

class _ProduccionPageState extends ConsumerState<ProduccionPage> {
  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final lotesAsync = ref.watch(lotesListProvider);

    return Column(
      children: [
        StickyTopbar(
          title: 'Directorio de Órdenes',
          searchHint: 'Buscar por Orden o Cliente...',
          searchController: _searchController,
          onSearchChanged: (value) => setState(() => _currentPage = 1),
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

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: ListTile(
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
                              title: Text(
                                'Orden: $ordenId',
                                style: AppTypography.body.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
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
                                onPressed: () {
                                  // 💡 AQUÍ NAVEGAMOS A LA NUEVA PANTALLA PASÁNDOLE LOS DATOS
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
                                },
                                icon: const Icon(Icons.view_kanban, size: 18),
                                label: const Text('Ver Tablero'),
                                style: ElevatedButton.styleFrom(
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
}
