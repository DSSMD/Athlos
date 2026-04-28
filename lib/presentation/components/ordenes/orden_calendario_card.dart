// ============================================================================
// orden_calendario_card.dart
// Ubicación: lib/presentation/components/ordenes/orden_calendario_card.dart
// Descripción: Card "Calendario de entregas" de la columna lateral (SCRUM-75).
// Muestra calendario mensual con marcadores por estado, leyenda, lista de
// entregas del mes, y banner de "Carga de trabajo" si hay aglomeración.
//
// Conectado a ordenesProvider para mostrar entregas reales de BD.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import 'orden_draft.dart';
import '../../../domain/models/orden_model.dart';
import '../../providers/orden_provider.dart';

/// Estado visual de una entrega en el calendario.
enum _EstadoEntrega { completada, enProduccion, pendiente, estaOrden }

/// Entrega real mapeada desde OrdenModel.
class _EntregaReal {
  final DateTime fecha;
  final String numOrden;
  final _EstadoEntrega estado;

  const _EntregaReal({
    required this.fecha,
    required this.numOrden,
    required this.estado,
  });
}

class OrdenCalendarioCard extends ConsumerStatefulWidget {
  final OrdenDraft draft;

  const OrdenCalendarioCard({super.key, required this.draft});

  @override
  ConsumerState<OrdenCalendarioCard> createState() =>
      _OrdenCalendarioCardState();
}

class _OrdenCalendarioCardState extends ConsumerState<OrdenCalendarioCard> {
  late DateTime _mesVisible;

  @override
  void initState() {
    super.initState();
    _mesVisible = widget.draft.fechaEntrega ?? DateTime.now();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MAPEO DE ORDENES REALES → ENTREGAS PARA EL CALENDARIO
  // ═══════════════════════════════════════════════════════════════════════════
  _EstadoEntrega _mapEstado(int idEstado) {
    switch (idEstado) {
      case 1:
        return _EstadoEntrega.pendiente; // Pendiente
      case 2:
        return _EstadoEntrega.enProduccion; // En Producción
      case 3:
      case 4:
        return _EstadoEntrega.completada; // Finalizada / Entregada
      default:
        return _EstadoEntrega.pendiente;
    }
  }

  List<_EntregaReal> _buildEntregas(List<OrdenModel> ordenes) {
    return ordenes
        .where((o) =>
            o.fechaEntrega.month == _mesVisible.month &&
            o.fechaEntrega.year == _mesVisible.year)
        .map((o) {
      final codigoCorto = o.numOrden.length > 8
          ? o.numOrden.substring(0, 8).toUpperCase()
          : o.numOrden.toUpperCase();
      return _EntregaReal(
        fecha: o.fechaEntrega,
        numOrden: codigoCorto,
        estado: _mapEstado(o.idEstado),
      );
    }).toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════════════════════
  Color _colorEstado(_EstadoEntrega e) {
    switch (e) {
      case _EstadoEntrega.completada:
        return AppColors.success;
      case _EstadoEntrega.enProduccion:
        return AppColors.warning;
      case _EstadoEntrega.pendiente:
        return AppColors.info;
      case _EstadoEntrega.estaOrden:
        return AppColors.primary500;
    }
  }

  String _labelEstado(_EstadoEntrega e) {
    switch (e) {
      case _EstadoEntrega.completada:
        return 'Completada';
      case _EstadoEntrega.enProduccion:
        return 'En prod.';
      case _EstadoEntrega.pendiente:
        return 'Pendiente';
      case _EstadoEntrega.estaOrden:
        return 'Nueva';
    }
  }

  String _nombreMes(DateTime d) {
    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];
    return '${meses[d.month - 1]} ${d.year}';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final ordenesAsync = ref.watch(ordenesProvider);
    final estaOrdenFecha = widget.draft.fechaEntrega;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: ordenesAsync.when(
        loading: () => Column(
          children: [
            _header(),
            const SizedBox(height: AppSpacing.xl2),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: AppSpacing.xl2),
          ],
        ),
        error: (e, s) => Column(
          children: [
            _header(),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Error al cargar entregas',
              style: AppTypography.small.copyWith(color: AppColors.error),
            ),
          ],
        ),
        data: (ordenes) {
          final entregas = _buildEntregas(ordenes);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              const SizedBox(height: AppSpacing.lg),
              _calendario(entregas, estaOrdenFecha),
              const SizedBox(height: AppSpacing.lg),
              _leyenda(),
              const SizedBox(height: AppSpacing.lg),
              _listaEntregas(entregas, estaOrdenFecha),
              if (_hayAglomeracion(entregas)) ...[
                const SizedBox(height: AppSpacing.lg),
                _bannerCargaTrabajo(entregas),
              ],
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _header() {
    return Row(
      children: [
        Text('Calendario de entregas', style: AppTypography.h3),
        const SizedBox(width: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            'En vivo',
            style: AppTypography.caption.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CALENDARIO
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _calendario(List<_EntregaReal> entregas, DateTime? estaOrdenFecha) {
    return TableCalendar(
      firstDay: DateTime(2020),
      lastDay: DateTime(2030),
      focusedDay: _mesVisible,
      locale: 'es_ES',
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        titleTextStyle: AppTypography.body.copyWith(
          fontWeight: FontWeight.w600,
        ),
        titleTextFormatter: (date, locale) => _nombreMes(date),
        leftChevronIcon: const Icon(
          Icons.chevron_left,
          size: 20,
          color: AppColors.textPrimary,
        ),
        rightChevronIcon: const Icon(
          Icons.chevron_right,
          size: 20,
          color: AppColors.textPrimary,
        ),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: AppTypography.caption.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
        weekendStyle: AppTypography.caption.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
        dowTextFormatter: (date, locale) {
          const dias = ['Lu', 'Ma', 'Mi', 'Ju', 'Vi', 'Sá', 'Do'];
          return dias[date.weekday - 1];
        },
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        defaultTextStyle: AppTypography.small,
        weekendTextStyle: AppTypography.small,
        todayDecoration: BoxDecoration(
          color: AppColors.neutral200,
          shape: BoxShape.circle,
        ),
        todayTextStyle: AppTypography.small.copyWith(
          fontWeight: FontWeight.w600,
        ),
        selectedDecoration: BoxDecoration(
          color: AppColors.primary500.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        selectedTextStyle: AppTypography.small.copyWith(
          color: AppColors.primary500,
          fontWeight: FontWeight.w700,
        ),
      ),
      selectedDayPredicate: (day) {
        if (estaOrdenFecha == null) return false;
        return isSameDay(day, estaOrdenFecha);
      },
      onPageChanged: (focusedDay) {
        setState(() => _mesVisible = focusedDay);
      },
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, _) {
          final entregasDelDia = entregas
              .where((e) => isSameDay(e.fecha, day))
              .toList();
          final esEstaOrden =
              estaOrdenFecha != null && isSameDay(day, estaOrdenFecha);

          if (entregasDelDia.isEmpty && !esEstaOrden) return null;

          return Positioned(
            bottom: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (esEstaOrden)
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: const BoxDecoration(
                      color: AppColors.primary500,
                      shape: BoxShape.circle,
                    ),
                  ),
                ...entregasDelDia.map(
                  (e) => Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: _colorEstado(e.estado),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEYENDA
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _leyenda() {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        _leyendaItem(AppColors.primary500, 'Esta orden'),
        _leyendaItem(AppColors.warning, 'En producción'),
        _leyendaItem(AppColors.success, 'Completada'),
        _leyendaItem(AppColors.info, 'Pendiente'),
      ],
    );
  }

  Widget _leyendaItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LISTA DE ENTREGAS DEL MES
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _listaEntregas(List<_EntregaReal> entregas, DateTime? estaOrdenFecha) {
    final tieneEstaOrden =
        estaOrdenFecha != null &&
        estaOrdenFecha.month == _mesVisible.month &&
        estaOrdenFecha.year == _mesVisible.year;
    final total = entregas.length + (tieneEstaOrden ? 1 : 0);

    final mesShort = _nombreMes(_mesVisible).split(' ').first.toLowerCase();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Entregas en $mesShort ($total órdenes)',
          style: AppTypography.small.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),

        if (entregas.isEmpty && !tieneEstaOrden)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              'No hay entregas programadas para este mes.',
              style: AppTypography.small.copyWith(color: AppColors.textMuted),
            ),
          ),

        ...entregas.map(
          (e) => _entregaRow(
            dia: e.fecha.day,
            numOrden: e.numOrden,
            estado: e.estado,
            esEstaOrden: false,
          ),
        ),
        if (tieneEstaOrden)
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.xs),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary500.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: _entregaRow(
              dia: estaOrdenFecha.day,
              numOrden: 'Esta orden',
              estado: _EstadoEntrega.estaOrden,
              esEstaOrden: true,
            ),
          ),
      ],
    );
  }

  Widget _entregaRow({
    required int dia,
    required String numOrden,
    required _EstadoEntrega estado,
    required bool esEstaOrden,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: _colorEstado(estado),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$dia ${_nombreMes(_mesVisible).split(' ').first.substring(0, 3).toLowerCase()}',
            style: AppTypography.small.copyWith(
              fontWeight: esEstaOrden ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              esEstaOrden ? numOrden : '#$numOrden',
              style: AppTypography.small,
            ),
          ),
          Text(
            _labelEstado(estado),
            style: AppTypography.small.copyWith(
              color: _colorEstado(estado),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BANNER CARGA DE TRABAJO
  // ═══════════════════════════════════════════════════════════════════════════
  bool _hayAglomeracion(List<_EntregaReal> entregas) {
    // Si hay 3+ entregas en una ventana de 5 días, mostramos el banner.
    if (entregas.length < 3) return false;
    final ordenadas = [...entregas]..sort((a, b) => a.fecha.compareTo(b.fecha));
    for (var i = 0; i <= ordenadas.length - 3; i++) {
      final diff = ordenadas[i + 2].fecha.difference(ordenadas[i].fecha);
      if (diff.inDays <= 5) return true;
    }
    return false;
  }

  Widget _bannerCargaTrabajo(List<_EntregaReal> entregas) {
    // Encontrar el rango de aglomeración real
    final ordenadas = [...entregas]..sort((a, b) => a.fecha.compareTo(b.fecha));
    int inicioAglom = 0;
    int finAglom = 2;
    for (var i = 0; i <= ordenadas.length - 3; i++) {
      final diff = ordenadas[i + 2].fecha.difference(ordenadas[i].fecha);
      if (diff.inDays <= 5) {
        inicioAglom = ordenadas[i].fecha.day;
        finAglom = ordenadas[i + 2].fecha.day;
        break;
      }
    }

    final mesCorto = _nombreMes(_mesVisible).split(' ').first.toLowerCase();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Text.rich(
        TextSpan(
          style: AppTypography.small,
          children: [
            TextSpan(
              text: 'Carga de trabajo: ',
              style: AppTypography.small.copyWith(
                color: AppColors.warning,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(
              text:
                  'Hay 3+ entregas entre el $inicioAglom-$finAglom de $mesCorto. '
                  'Considera si el equipo tiene capacidad para entregar esta orden.',
            ),
          ],
        ),
      ),
    );
  }
}
