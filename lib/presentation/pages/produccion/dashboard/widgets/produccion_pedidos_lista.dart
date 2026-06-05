// ============================================================================
// produccion_pedidos_lista.dart
// Ubicación: lib/presentation/pages/produccion/dashboard/widgets/produccion_pedidos_lista.dart
// Descripción: Lista de pedidos en producción activa (idEstado 1 o 2) para
// la tab "Métricas" del dashboard de producción.
//
// Filtro: orden.idEstado == 1 (Pendiente) || orden.idEstado == 2 (En Producción).
// No se incluyen Finalizadas (3) ni Entregadas (4).
//
// Orden (prioridad descendente):
//   1. Retrasadas primero, con más días de retraso arriba.
//   2. Próximas a vencer (≤ 4 días) ordenadas por cercanía a la fecha.
//   3. Resto, por fechaEntrega ascendente.
//
// Flags por fila/card:
//   - Retrasada      → warning_amber_rounded + tooltip.
//   - Próx. a vencer → schedule + tooltip.
//   - Normal         → SizedBox (mantiene la columna alineada en desktop).
//
// Layout responsive: tabla en desktop, cards verticales en mobile.
// Lista cargada en memoria; se asume volumen acotado a decenas de órdenes
// activas, por eso no se pagina.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../../domain/models/orden_model.dart';
import '../../../../providers/orden_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../../../theme/breakpoints.dart';
import '../../../../widgets/shared/empty_state.dart';

// ─── Helpers de prioridad (puros, sobre OrdenModel + DateTime) ──────────────

// Retrasada: aún no entregada y la fecha objetivo ya pasó.
bool _esRetrasada(OrdenModel o, DateTime now) =>
    o.idEstado != 4 && o.fechaEntrega.isBefore(now);

// Próxima a vencer: no retrasada, pero entrega dentro de los próximos 4 días.
bool _esProxAVencer(OrdenModel o, DateTime now) =>
    o.idEstado != 4 &&
    !_esRetrasada(o, now) &&
    o.fechaEntrega.isBefore(now.add(const Duration(days: 4)));

class ProduccionPedidosLista extends ConsumerWidget {
  const ProduccionPedidosLista({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordenesAsync = ref.watch(ordenesProvider);
    final isMobile = context.isMobile;

    return ordenesAsync.when(
      // Altura fija en loading/empty: este widget vive dentro de un
      // SingleChildScrollView (ver produccion_metricas_tab.dart) que pasa
      // constraints unbounded en height. Sin esta caja, Center/EmptyState
      // intentan expandirse a infinity y rompen el layout.
      loading: () => const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          'Error al cargar los pedidos en producción:\n$error',
          style: AppTypography.small.copyWith(color: AppColors.error),
          textAlign: TextAlign.center,
        ),
      ),
      data: (ordenes) {
        final now = DateTime.now();
        final pedidos = _filtrarYOrdenar(ordenes, now);

        if (pedidos.isEmpty) {
          return const SizedBox(
            height: 200,
            child: EmptyState(
              icon: Icons.factory_outlined,
              title: 'No hay pedidos en producción',
              subtitle: 'Cuando se registren órdenes activas, aparecerán aquí.',
            ),
          );
        }

        return isMobile
            ? _PedidosCards(pedidos: pedidos, now: now)
            : _PedidosTabla(pedidos: pedidos, now: now);
      },
    );
  }

  // ─── Filtro + orden ─────────────────────────────────────────────────────────

  List<OrdenModel> _filtrarYOrdenar(List<OrdenModel> ordenes, DateTime now) {
    final activos = ordenes
        .where((o) => o.idEstado == 1 || o.idEstado == 2)
        .toList();

    activos.sort((a, b) {
      final aRetrasada = _esRetrasada(a, now);
      final bRetrasada = _esRetrasada(b, now);

      // Retrasadas primero. Entre dos retrasadas, la más vieja arriba
      // (más días vencida = más urgente).
      if (aRetrasada && !bRetrasada) return -1;
      if (!aRetrasada && bRetrasada) return 1;
      if (aRetrasada && bRetrasada) {
        return a.fechaEntrega.compareTo(b.fechaEntrega);
      }

      final aProx = _esProxAVencer(a, now);
      final bProx = _esProxAVencer(b, now);

      // Próximas a vencer segundo, las más cercanas arriba.
      if (aProx && !bProx) return -1;
      if (!aProx && bProx) return 1;
      if (aProx && bProx) {
        return a.fechaEntrega.compareTo(b.fechaEntrega);
      }

      // Resto, por fechaEntrega ascendente.
      return a.fechaEntrega.compareTo(b.fechaEntrega);
    });

    return activos;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TABLA — layout desktop
// ═════════════════════════════════════════════════════════════════════════════
class _PedidosTabla extends StatelessWidget {
  const _PedidosTabla({required this.pedidos, required this.now});

  final List<OrdenModel> pedidos;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: const [
                _HeaderCell('ORDEN', flex: 2),
                _HeaderCell('CLIENTE', flex: 3),
                _HeaderCell('F. ENTREGA', flex: 2),
                _HeaderCell('TOTAL', flex: 2),
                _HeaderCell('ESTADO', flex: 2),
                _HeaderCell('', flex: 1),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),
          for (final o in pedidos) ...[
            _PedidoRow(orden: o, now: now),
            if (o != pedidos.last)
              const Divider(height: 1, color: AppColors.border),
          ],
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label, {required this.flex});

  final String label;
  final int flex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _PedidoRow extends StatelessWidget {
  const _PedidoRow({required this.orden, required this.now});

  final OrdenModel orden;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final fechaFmt = DateFormat(
      'd MMM yyyy',
      'es_ES',
    ).format(orden.fechaEntrega);
    final totalFmt = 'Bs. ${orden.costoTotal.toStringAsFixed(2)}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '#${_shortId(orden.numOrden)}',
              style: AppTypography.small.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              orden.clienteNombre,
              style: AppTypography.small,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          Expanded(flex: 2, child: Text(fechaFmt, style: AppTypography.small)),
          Expanded(
            flex: 2,
            child: Text(
              totalFmt,
              style: AppTypography.small.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(flex: 2, child: _EstadoChip(idEstado: orden.idEstado)),
          Expanded(
            flex: 1,
            child: _FlagIcon(orden: orden, now: now),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CARDS — layout mobile
// ═════════════════════════════════════════════════════════════════════════════
class _PedidosCards extends StatelessWidget {
  const _PedidosCards({required this.pedidos, required this.now});

  final List<OrdenModel> pedidos;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final o in pedidos) ...[
          _PedidoCard(orden: o, now: now),
          if (o != pedidos.last) const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _PedidoCard extends StatelessWidget {
  const _PedidoCard({required this.orden, required this.now});

  final OrdenModel orden;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final fechaFmt = DateFormat(
      'd MMM yyyy',
      'es_ES',
    ).format(orden.fechaEntrega);
    final totalFmt = 'Bs. ${orden.costoTotal.toStringAsFixed(2)}';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '#${_shortId(orden.numOrden)}',
                  style: AppTypography.h3,
                ),
              ),
              _EstadoChip(idEstado: orden.idEstado),
              const SizedBox(width: AppSpacing.sm),
              _FlagIcon(orden: orden, now: now),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(orden.clienteNombre, style: AppTypography.body),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  fechaFmt,
                  style: AppTypography.small.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              Text(
                totalFmt,
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// CHIP DE ESTADO — replica el esquema de colores de orden_page (_StatusBadge)
// ═════════════════════════════════════════════════════════════════════════════
class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.idEstado});

  final int idEstado;

  @override
  Widget build(BuildContext context) {
    // 1=Pendiente (orange), 2=En Producción (blue/primary500). En esta lista
    // sólo aparecen estos dos estados por filtro previo; el default queda
    // como red de seguridad por si llega otro valor.
    final (color, label) = switch (idEstado) {
      1 => (Colors.orange, 'Pendiente'),
      2 => (AppColors.primary500, 'En Producción'),
      _ => (Colors.grey, 'Desconocido'),
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// FLAG ICON — retraso / próximo a vencer / nada
// ═════════════════════════════════════════════════════════════════════════════
class _FlagIcon extends StatelessWidget {
  const _FlagIcon({required this.orden, required this.now});

  final OrdenModel orden;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    if (_esRetrasada(orden, now)) {
      return const Tooltip(
        message: 'Retrasada',
        child: Icon(
          Icons.warning_amber_rounded,
          color: AppColors.error,
          size: 20,
        ),
      );
    }
    if (_esProxAVencer(orden, now)) {
      return const Tooltip(
        message: 'Próximo a vencer (4 días o menos)',
        child: Icon(Icons.schedule, color: AppColors.warning, size: 20),
      );
    }
    // SizedBox vacío para mantener la columna alineada en la tabla desktop.
    return const SizedBox(width: 20, height: 20);
  }
}

// ─── Util ───────────────────────────────────────────────────────────────────

String _shortId(String numOrden) => numOrden.length > 8
    ? numOrden.substring(0, 8).toUpperCase()
    : numOrden.toUpperCase();
