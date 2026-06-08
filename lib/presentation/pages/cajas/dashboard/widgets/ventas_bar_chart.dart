// ============================================================================
// ventas_bar_chart.dart
// Gráfico de barras de ventas (suma de costo_total) por período: día / semana /
// mes. Dibujado a mano con CustomPainter — sin librería de gráficos, siguiendo
// la convención del dashboard de administración.
// La agregación se hace client-side a partir de la lista de OrdenModel que
// entrega ordenesProvider (campos fechaOrden + costoTotal).
// ============================================================================

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../theme/app_colors.dart';
import '../../../../theme/app_spacing.dart';
import '../../../../theme/app_typography.dart';
import '../../../../../domain/models/orden_model.dart';

enum _Periodo { dia, semana, mes }

extension _PeriodoLabel on _Periodo {
  String get label => switch (this) {
        _Periodo.dia => 'Día',
        _Periodo.semana => 'Semana',
        _Periodo.mes => 'Mes',
      };
}

/// Una barra del gráfico: etiqueta del eje X + monto acumulado.
class _Bucket {
  const _Bucket(this.label, this.monto);
  final String label;
  final double monto;
}

class VentasBarChart extends StatefulWidget {
  const VentasBarChart({super.key, required this.ordenes});
  final List<OrdenModel> ordenes;

  @override
  State<VentasBarChart> createState() => _VentasBarChartState();
}

class _VentasBarChartState extends State<VentasBarChart> {
  _Periodo _periodo = _Periodo.semana;

  @override
  Widget build(BuildContext context) {
    final buckets = _calcularBuckets(_periodo);
    final maxMonto =
        buckets.fold<double>(0, (m, b) => b.monto > m ? b.monto : m);
    final totalPeriodo = buckets.fold<double>(0, (s, b) => s + b.monto);
    final moneda =
        NumberFormat.currency(symbol: 'Bs. ', decimalDigits: 0, locale: 'es_BO');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VENTAS POR PERÍODO',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total: ${moneda.format(totalPeriodo)}',
                      style: AppTypography.small
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              _PeriodoSelector(
                seleccionado: _periodo,
                onChanged: (p) => setState(() => _periodo = p),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (totalPeriodo <= 0)
            const SizedBox(
              height: 180,
              child: Center(
                child: Text(
                  'Sin ventas registradas en el período.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            )
          else
            SizedBox(
              height: 200,
              width: double.infinity,
              child: CustomPaint(
                painter: _BarChartPainter(buckets: buckets, maxMonto: maxMonto),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Agregación client-side ──────────────────────────────────────────────
  List<_Bucket> _calcularBuckets(_Periodo periodo) {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    switch (periodo) {
      case _Periodo.dia:
        // Últimos 7 días (incluye hoy).
        return List.generate(7, (i) {
          final dia = hoy.subtract(Duration(days: 6 - i));
          final monto = _sumarEnRango(
            dia,
            dia.add(const Duration(days: 1)),
          );
          return _Bucket(_diaSemanaCorto(dia), monto);
        });
      case _Periodo.semana:
        // Últimas 6 semanas (ventanas de 7 días).
        return List.generate(6, (i) {
          final fin = hoy.subtract(Duration(days: 7 * (5 - i)));
          final inicio = fin.subtract(const Duration(days: 6));
          final monto = _sumarEnRango(
            inicio,
            fin.add(const Duration(days: 1)),
          );
          return _Bucket(DateFormat('dd/MM').format(inicio), monto);
        });
      case _Periodo.mes:
        // Últimos 6 meses calendario.
        return List.generate(6, (i) {
          final ref = DateTime(ahora.year, ahora.month - (5 - i), 1);
          final inicio = ref;
          final fin = DateTime(ref.year, ref.month + 1, 1);
          final monto = _sumarEnRango(inicio, fin);
          return _Bucket(
            DateFormat('MMM', 'es').format(ref),
            monto,
          );
        });
    }
  }

  /// Suma costo_total de las órdenes cuya fechaOrden cae en [inicio, fin).
  double _sumarEnRango(DateTime inicio, DateTime fin) {
    return widget.ordenes
        .where((o) =>
            !o.fechaOrden.isBefore(inicio) && o.fechaOrden.isBefore(fin))
        .fold<double>(0, (sum, o) => sum + o.costoTotal);
  }

  String _diaSemanaCorto(DateTime d) {
    const dias = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return dias[d.weekday - 1];
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SELECTOR DE PERÍODO (pills)
// ═════════════════════════════════════════════════════════════════════════════
class _PeriodoSelector extends StatelessWidget {
  const _PeriodoSelector({required this.seleccionado, required this.onChanged});
  final _Periodo seleccionado;
  final ValueChanged<_Periodo> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.xs,
      children: _Periodo.values.map((p) {
        final activo = p == seleccionado;
        return GestureDetector(
          onTap: () => onChanged(p),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: activo ? AppColors.primary500 : AppColors.neutral100,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Text(
              p.label,
              style: AppTypography.caption.copyWith(
                color: activo ? AppColors.brandWhite : AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// PAINTER DE BARRAS
// ═════════════════════════════════════════════════════════════════════════════
class _BarChartPainter extends CustomPainter {
  _BarChartPainter({required this.buckets, required this.maxMonto});
  final List<_Bucket> buckets;
  final double maxMonto;

  @override
  void paint(Canvas canvas, Size size) {
    if (buckets.isEmpty) return;

    const double topPad = 22; // etiqueta de valor sobre la barra
    const double bottomPad = 24; // etiqueta del eje X
    const double sidePad = 4;
    final double chartHeight = size.height - topPad - bottomPad;
    final double chartBottom = topPad + chartHeight;

    // Línea base.
    final baseline = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, chartBottom),
      Offset(size.width, chartBottom),
      baseline,
    );

    final int n = buckets.length;
    final double slot = (size.width - sidePad * 2) / n;
    final double barW = (slot * 0.52).clamp(10.0, 44.0);

    for (var i = 0; i < n; i++) {
      final b = buckets[i];
      final double ratio = maxMonto > 0 ? b.monto / maxMonto : 0;
      final double barH =
          (ratio * chartHeight).clamp(b.monto > 0 ? 4.0 : 0.0, chartHeight);
      final double cx = sidePad + slot * i + slot / 2;
      final double left = cx - barW / 2;
      final double top = chartBottom - barH;

      if (barH > 0) {
        final rect = Rect.fromLTWH(left, top, barW, barH);
        final paint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary500,
              AppColors.primary500.withValues(alpha: 0.65),
            ],
          ).createShader(rect);
        canvas.drawRRect(
          RRect.fromRectAndCorners(
            rect,
            topLeft: const Radius.circular(6),
            topRight: const Radius.circular(6),
          ),
          paint,
        );
      }

      // Etiqueta de valor (solo si hay monto).
      if (b.monto > 0) {
        _texto(
          canvas,
          _compacto(b.monto),
          Offset(cx, top - 4),
          fontSize: 10,
          color: AppColors.textPrimary,
          anchorBottom: true,
        );
      }

      // Etiqueta del eje X.
      _texto(
        canvas,
        b.label,
        Offset(cx, chartBottom + 6),
        fontSize: 10,
        color: AppColors.textSecondary,
        anchorBottom: false,
      );
    }
  }

  void _texto(
    Canvas canvas,
    String text,
    Offset center, {
    required double fontSize,
    required Color color,
    required bool anchorBottom,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = center.dx - tp.width / 2;
    final dy = anchorBottom ? center.dy - tp.height : center.dy;
    tp.paint(canvas, Offset(dx, dy));
  }

  String _compacto(double v) {
    if (v >= 1000) {
      final miles = v / 1000;
      return '${miles.toStringAsFixed(miles >= 10 ? 0 : 1)}k';
    }
    return v.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.buckets != buckets || oldDelegate.maxMonto != maxMonto;
}
