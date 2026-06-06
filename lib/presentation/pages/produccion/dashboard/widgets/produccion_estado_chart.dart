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
import 'package:intl/intl.dart';

import '../../../../../domain/models/orden_model.dart';
import '../../../../providers/orden_provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../../../theme/breakpoints.dart';

// ─── Helpers de prioridad (duplican intencionalmente la lógica de
// produccion_pedidos_lista.dart). Allí están como top-level privadas y
// no pueden importarse desde este archivo. Si la duplicación crece a un
// tercer consumidor, extraer a produccion_helpers.dart.

bool _esRetrasada(OrdenModel o, DateTime now) =>
    o.idEstado != 4 && o.fechaEntrega.isBefore(now);

bool _esProxAVencer(OrdenModel o, DateTime now) =>
    o.idEstado != 4 &&
    !_esRetrasada(o, now) &&
    o.fechaEntrega.isBefore(now.add(const Duration(days: 4)));

// Mismos primeros 8 chars que usa pedidos_lista para que las dos vistas
// muestren el mismo identificador legible.
String _shortId(String numOrden) => numOrden.length > 8
    ? numOrden.substring(0, 8).toUpperCase()
    : numOrden.toUpperCase();

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

    return _ChartFrame(
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
    final panel = _PedidosCriticosPanel(ordenes: ordenes);

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row con mainAxis center centra horizontalmente sin pedir altura
          // infinita. Center expande en los dos ejes y dentro de la Column
          // (constraints verticales unbounded) eso revienta el layout.
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [donut]),
          const SizedBox(height: AppSpacing.lg),
          leyenda,
          const SizedBox(height: AppSpacing.lg),
          panel,
        ],
      );
    }

    // Desktop: izquierda = donut + leyenda apilados; derecha = panel de
    // pedidos críticos en una Expanded para llenar el card.
    //
    // Ancho fijo (240) del lado izquierdo: la _Leyenda usa flex internos
    // (Expanded/Spacer) que exigen ancho bounded. Sin este SizedBox, la
    // Column intermedia hace shrink-wrap y consulta intrinsic width →
    // RenderFlex crashea con "non-zero flex but incoming width
    // constraints are unbounded". El Donut va centrado horizontalmente
    // dentro de los 240px con un Row(mainAxis: center).
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 240,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [donut],
              ),
              const SizedBox(height: AppSpacing.lg),
              leyenda,
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(child: panel),
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

// ═════════════════════════════════════════════════════════════════════════════
// PANEL DE PEDIDOS CRÍTICOS — top 5 retrasados / próximos a vencer.
// Iconos estáticos a propósito: las flags pulsantes viven en la lista grande
// de abajo, acá se enfatiza por ubicación + título, no por animación
// (evita competencia visual entre dos secciones que parpadean a la vez).
// ═════════════════════════════════════════════════════════════════════════════
class _PedidosCriticosPanel extends StatelessWidget {
  const _PedidosCriticosPanel({required this.ordenes});

  final List<OrdenModel> ordenes;

  // Máximo de items a mostrar en el panel. Mantiene la altura del panel
  // acotada para que no empuje al donut/leyenda hacia abajo en desktop.
  static const int _kMaxItems = 5;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Sólo activos (1 ó 2) y sólo críticos (retrasados o próximos a vencer).
    // Los pedidos "normales" no entran al panel — para eso está la lista
    // completa de abajo. Acá es exclusivamente atención inmediata.
    final criticos = ordenes
        .where(
          (o) =>
              (o.idEstado == 1 || o.idEstado == 2) &&
              (_esRetrasada(o, now) || _esProxAVencer(o, now)),
        )
        .toList();

    criticos.sort((a, b) {
      final aRetrasada = _esRetrasada(a, now);
      final bRetrasada = _esRetrasada(b, now);

      // Retrasados antes que próximos a vencer. Dentro de cada grupo, más
      // cerca/más viejo arriba (siempre fechaEntrega ascendente).
      if (aRetrasada && !bRetrasada) return -1;
      if (!aRetrasada && bRetrasada) return 1;
      return a.fechaEntrega.compareTo(b.fechaEntrega);
    });

    final top = criticos.take(_kMaxItems).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Pedidos críticos', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        if (top.isEmpty)
          Text(
            'Sin pedidos críticos',
            style: AppTypography.small.copyWith(color: AppColors.textMuted),
          )
        else
          for (var i = 0; i < top.length; i++) ...[
            _CriticoItem(orden: top[i], now: now),
            if (i < top.length - 1) const SizedBox(height: AppSpacing.sm),
          ],
      ],
    );
  }
}

class _CriticoItem extends StatelessWidget {
  const _CriticoItem({required this.orden, required this.now});

  final OrdenModel orden;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final retrasada = _esRetrasada(orden, now);
    final icon = retrasada ? Icons.warning_amber_rounded : Icons.schedule;
    final color = retrasada ? AppColors.error : AppColors.warning;

    final fechaFmt = DateFormat(
      'd MMM yyyy',
      'es_ES',
    ).format(orden.fechaEntrega);
    final cliente = orden.clienteNombre.trim().isEmpty
        ? '—'
        : orden.clienteNombre;

    // Fila horizontal compacta: [icono] [#orden 100px] [cliente flex] [fecha].
    // Una sola línea por item aprovecha el ancho del panel (Expanded en
    // desktop) en vez de apilar 3 textos cortos con whitespace a la derecha.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 100,
          child: Text(
            '#${_shortId(orden.numOrden)}',
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w700),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            cliente,
            style: AppTypography.small.copyWith(color: AppColors.textMuted),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          fechaFmt,
          style: AppTypography.small.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}
