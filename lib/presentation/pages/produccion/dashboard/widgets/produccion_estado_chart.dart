// ============================================================================
// produccion_estado_chart.dart
// Ubicación: lib/presentation/pages/produccion/dashboard/widgets/produccion_estado_chart.dart
// Descripción: Donut chart de breakdown de pedidos por estado productivo,
// para la tab "Métricas" del dashboard de producción.
//
// Estados graficados:
//   - Pendiente   (idEstado == 1)  → naranja  (mismo color que el chip)
//   - En Producción (idEstado == 2) → primary500 (mismo color que el chip)
//   - Finalizada  (idEstado == 3)  → verde     (matchea el donut del admin)
//
// Por qué excluimos idEstado == 4 (Entregada): una vez entregada, la orden
// salió del flujo productivo. El chart representa carga activa en planta,
// no histórico de ventas.
//
// Patrón inspirado en el donut del admin dashboard
// (admin/dashboard/dashboard_page.dart): CustomPainter inline (no se
// extrae a shared) con drawArc + StrokeCap.round, centro con total + label,
// leyenda con dots + counts. Se replica la técnica, no el código textual.
//
// Layout responsive:
//   - Desktop (>= 1100): Row → donut a la izquierda, leyenda a la derecha.
//   - Mobile  (< 1100):  Column → donut arriba, leyenda abajo.
//
// Estados del AsyncValue:
//   - loading       → caja de altura fija (280px) con spinner centrado,
//                     para no romper el layout dentro del SingleChildScrollView
//                     ancestor (mismo aprendizaje que en pedidos_lista).
//   - error         → texto breve con AppColors.error.
//   - data total=0  → mensaje "Sin pedidos activos" (evita donut vacío).
//   - data total>0  → donut con arcos proporcionales al count.
// ============================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../domain/models/orden_model.dart';
import '../../../../providers/orden_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../../../theme/breakpoints.dart';

// ─── Dimensiones del donut ─────────────────────────────────────────────────

// Tamaño del SizedBox que envuelve el CustomPaint + centro. La caja interna
// del painter es un poco más chica para dejar margen al StrokeCap.round.
const double _kDonutSize = 180;
const double _kDonutStroke = 14;
// Altura fija del placeholder de loading. Aproxima la altura final del
// chart (título + donut + padding) para que el layout no salte cuando
// terminan de cargar los datos.
const double _kLoadingHeight = 280;

class ProduccionEstadoChart extends ConsumerWidget {
  const ProduccionEstadoChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordenesAsync = ref.watch(ordenesProvider);
    final isMobile = context.isMobile;

    final card = _ChartFrame(
      child: ordenesAsync.when(
        loading: () => const SizedBox(
          height: _kLoadingHeight,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            'Error al cargar el breakdown:\n$error',
            style: AppTypography.small.copyWith(color: AppColors.error),
            textAlign: TextAlign.center,
          ),
        ),
        data: (ordenes) => _buildChart(ordenes, isMobile),
      ),
    );

    // Mobile: el card ocupa el ancho disponible (la columna ya está
    // ajustada al device). Desktop: lo capamos a 700px y centramos para
    // evitar que la leyenda se estire al borde derecho del shell.
    if (isMobile) return card;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: card,
      ),
    );
  }

  Widget _buildChart(List<OrdenModel> ordenes, bool isMobile) {
    final segmentos = _segmentosFromOrdenes(ordenes);
    final total = segmentos.fold<int>(0, (acc, s) => acc + s.count);

    if (total == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(
          child: Text('Sin pedidos activos', style: AppTypography.body),
        ),
      );
    }

    final donut = _Donut(segmentos: segmentos, total: total);
    final leyenda = _Leyenda(segmentos: segmentos);

    if (isMobile) {
      return Column(
        children: [
          donut,
          const SizedBox(height: AppSpacing.lg),
          leyenda,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        donut,
        const SizedBox(width: AppSpacing.xl2),
        Expanded(child: leyenda),
      ],
    );
  }

  // Counts + colores. Orden fijo: el painter dibuja arcos siguiendo este
  // mismo orden empezando arriba (-π/2) y avanzando en sentido horario.
  List<_EstadoSegmento> _segmentosFromOrdenes(List<OrdenModel> ordenes) {
    final int pendientes = ordenes.where((o) => o.idEstado == 1).length;
    final int enProduccion = ordenes.where((o) => o.idEstado == 2).length;
    final int finalizadas = ordenes.where((o) => o.idEstado == 3).length;

    return [
      _EstadoSegmento(
        label: 'Pendiente',
        count: pendientes,
        color: Colors.orange,
      ),
      _EstadoSegmento(
        label: 'En Producción',
        count: enProduccion,
        color: AppColors.primary500,
      ),
      _EstadoSegmento(
        label: 'Finalizada',
        count: finalizadas,
        color: Colors.green,
      ),
    ];
  }
}

// ─── Datos por segmento ─────────────────────────────────────────────────────

class _EstadoSegmento {
  const _EstadoSegmento({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;
}

// ═════════════════════════════════════════════════════════════════════════════
// FRAME — Container con título y borde. Reutilizado para todos los estados
// (loading / error / empty / data) así el visual no salta.
// ═════════════════════════════════════════════════════════════════════════════
class _ChartFrame extends StatelessWidget {
  const _ChartFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Distribución por estado', style: AppTypography.h3),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// DONUT — CustomPaint + total en el centro
// ═════════════════════════════════════════════════════════════════════════════
class _Donut extends StatelessWidget {
  const _Donut({required this.segmentos, required this.total});

  final List<_EstadoSegmento> segmentos;
  final int total;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _kDonutSize,
      height: _kDonutSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(_kDonutSize, _kDonutSize),
            painter: _EstadoDonutPainter(
              segmentos: segmentos,
              strokeWidth: _kDonutStroke,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$total',
                style: AppTypography.h1.copyWith(fontWeight: FontWeight.w700),
              ),
              Text(
                'TOTAL',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// LEYENDA — fila por segmento (color dot + label + count + %)
// ═════════════════════════════════════════════════════════════════════════════
class _Leyenda extends StatelessWidget {
  const _Leyenda({required this.segmentos});

  final List<_EstadoSegmento> segmentos;

  @override
  Widget build(BuildContext context) {
    final total = segmentos.fold<int>(0, (acc, s) => acc + s.count);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < segmentos.length; i++) ...[
          _LeyendaRow(segmento: segmentos[i], total: total),
          if (i < segmentos.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _LeyendaRow extends StatelessWidget {
  const _LeyendaRow({required this.segmento, required this.total});

  final _EstadoSegmento segmento;
  final int total;

  @override
  Widget build(BuildContext context) {
    final double pct = total > 0 ? (segmento.count / total) * 100 : 0.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: segmento.color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            segmento.label,
            style: AppTypography.small.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '${segmento.count}',
          style: AppTypography.small.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '(${pct.toStringAsFixed(0)}%)',
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PAINTER — arcos proporcionales sobre un círculo, partiendo de las 12hs
// ═════════════════════════════════════════════════════════════════════════════
class _EstadoDonutPainter extends CustomPainter {
  const _EstadoDonutPainter({
    required this.segmentos,
    required this.strokeWidth,
  });

  final List<_EstadoSegmento> segmentos;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final int total = segmentos.fold<int>(0, (acc, s) => acc + s.count);

    // Anillo base sobre el que se dibujan los arcos. El radius queda
    // recortado por el strokeWidth para que el trazo no se coma la caja.
    final Offset center = size.center(Offset.zero);
    final double radius =
        (math.min(size.width, size.height) / 2) - strokeWidth / 2;
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    // Si no hay nada, mostramos un anillo gris (red de seguridad: el caller
    // ya intercepta total == 0 antes de instanciar el painter).
    if (total == 0) {
      final basePaint = Paint()
        ..color = AppColors.neutral100
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius, basePaint);
      return;
    }

    // Arrancamos arriba (-π/2 = 12 en punto) y avanzamos en sentido horario.
    double startAngle = -math.pi / 2;

    for (final s in segmentos) {
      if (s.count == 0) continue;

      final double sweep = (s.count / total) * 2 * math.pi;
      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _EstadoDonutPainter old) {
    if (old.strokeWidth != strokeWidth) return true;
    if (old.segmentos.length != segmentos.length) return true;
    for (var i = 0; i < segmentos.length; i++) {
      if (old.segmentos[i].count != segmentos[i].count) return true;
      if (old.segmentos[i].color != segmentos[i].color) return true;
    }
    return false;
  }
}
