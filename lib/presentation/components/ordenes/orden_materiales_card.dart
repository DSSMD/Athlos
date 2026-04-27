// ============================================================================
// orden_materiales_card.dart
// Ubicación: lib/presentation/components/ordenes/orden_materiales_card.dart
// Descripción: Card "Materiales requeridos (calculadora)" del form Crear
// Orden (SCRUM-75).
//
// Desktop (>= 600px del card): tabla con MATERIAL / REQUERIDO / STOCK ACTUAL /
// DESPUÉS / ESTADO.
// Mobile (< 600px): lista de mini-cards apiladas con la misma info.
//
// Banner de alerta si algún material está insuficiente.
// MOCK FIJO: 4 materiales del Figma.
// ============================================================================

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import 'orden_draft.dart';

class OrdenMaterialesCard extends StatelessWidget {
  final OrdenDraft draft;
  final ValueChanged<OrdenDraft> onChanged;

  const OrdenMaterialesCard({
    super.key,
    required this.draft,
    required this.onChanged,
  });

  static const double _compactBreakpoint = 600;

  // ═══════════════════════════════════════════════════════════════════════════
  // MOCK FIJO
  // ═══════════════════════════════════════════════════════════════════════════
  static const List<OrdenMaterialRequerido> _materialesMock = [
    OrdenMaterialRequerido(
      material: 'Tela algodón azul marino',
      requerido: 250,
      stockActual: 380,
      unidad: 'mts',
    ),
    OrdenMaterialRequerido(
      material: 'Hilo azul #120',
      requerido: 50,
      stockActual: 12,
      unidad: 'conos',
    ),
    OrdenMaterialRequerido(
      material: 'Botones plástico blanco',
      requerido: 2500,
      stockActual: 4000,
      unidad: 'uds',
    ),
    OrdenMaterialRequerido(
      material: 'Etiquetas talla',
      requerido: 500,
      stockActual: 620,
      unidad: 'uds',
    ),
  ];

  void _recalcular() {
    onChanged(draft.copyWith(materiales: _materialesMock));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final materiales = draft.materiales.isEmpty
        ? _materialesMock
        : draft.materiales;

    final materialInsuficiente = materiales.firstWhere(
      (m) => m.estado == 'insuficiente',
      orElse: () => const OrdenMaterialRequerido(
        material: '',
        requerido: 0,
        stockActual: 0,
        unidad: '',
      ),
    );
    final hayInsuficiente = materialInsuficiente.material.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < _compactBreakpoint;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(isCompact),
              const SizedBox(height: AppSpacing.lg),
              if (isCompact)
                _listaMobile(materiales)
              else
                _tablaDesktop(materiales),
              if (hayInsuficiente) ...[
                const SizedBox(height: AppSpacing.lg),
                _bannerAlerta(materialInsuficiente),
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
  Widget _header(bool isCompact) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            'Materiales requeridos (calculadora)',
            style: AppTypography.h3,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        if (isCompact)
          IconButton(
            onPressed: _recalcular,
            icon: const Icon(Icons.refresh),
            tooltip: 'Recalcular',
            color: AppColors.textPrimary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          )
        else
          OutlinedButton.icon(
            onPressed: _recalcular,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Recalcular'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TABLA DESKTOP
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _tablaDesktop(List<OrdenMaterialRequerido> materiales) {
    return Column(
      children: [
        _headerTabla(),
        const Divider(height: 1, color: AppColors.border),
        for (var i = 0; i < materiales.length; i++) ...[
          _MaterialRowDesktop(material: materiales[i]),
          if (i < materiales.length - 1)
            const Divider(height: 1, color: AppColors.border),
        ],
      ],
    );
  }

  Widget _headerTabla() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          _col('MATERIAL', 4),
          _col('REQUERIDO', 2),
          _col('STOCK ACTUAL', 2),
          _col('DESPUÉS', 2),
          _col('ESTADO', 2),
        ],
      ),
    );
  }

  Widget _col(String label, int flex) => Expanded(
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

  // ═══════════════════════════════════════════════════════════════════════════
  // LISTA MOBILE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _listaMobile(List<OrdenMaterialRequerido> materiales) {
    return Column(
      children: [
        for (var i = 0; i < materiales.length; i++) ...[
          _MaterialRowMobile(material: materiales[i]),
          if (i < materiales.length - 1) const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BANNER ALERTA
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _bannerAlerta(OrdenMaterialRequerido m) {
    final faltante = m.requerido - m.stockActual;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 20,
            color: AppColors.error,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: AppTypography.small,
                children: [
                  TextSpan(
                    text: 'Alerta:  ',
                    style: AppTypography.small.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                  TextSpan(
                    text:
                        '${m.material} insuficiente. Se requiere compra de '
                        'al menos ${faltante.toStringAsFixed(0)} ${m.unidad}.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// FILA DESKTOP
// ═════════════════════════════════════════════════════════════════════════════
class _MaterialRowDesktop extends StatelessWidget {
  final OrdenMaterialRequerido material;
  const _MaterialRowDesktop({required this.material});

  @override
  Widget build(BuildContext context) {
    final despues = material.despues;
    final esInsuficiente = material.estado == 'insuficiente';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              material.material,
              style: AppTypography.small,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${material.requerido.toStringAsFixed(0)} ${material.unidad}',
              style: AppTypography.small,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${material.stockActual.toStringAsFixed(0)} ${material.unidad}',
              style: AppTypography.small,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${despues.toStringAsFixed(0)} ${material.unidad}',
              style: AppTypography.small.copyWith(
                color: esInsuficiente ? AppColors.error : AppColors.textPrimary,
                fontWeight: esInsuficiente ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ),
          Expanded(flex: 2, child: _BadgeEstado(estado: material.estado)),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// FILA MOBILE — mini-card
// ═════════════════════════════════════════════════════════════════════════════
class _MaterialRowMobile extends StatelessWidget {
  final OrdenMaterialRequerido material;
  const _MaterialRowMobile({required this.material});

  @override
  Widget build(BuildContext context) {
    final despues = material.despues;
    final esInsuficiente = material.estado == 'insuficiente';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Línea 1: nombre + badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  material.material,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _BadgeEstado(estado: material.estado),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Línea 2: 3 mini-info en row
          Row(
            children: [
              Expanded(
                child: _miniInfo(
                  label: 'Requerido',
                  value:
                      '${material.requerido.toStringAsFixed(0)} ${material.unidad}',
                ),
              ),
              Expanded(
                child: _miniInfo(
                  label: 'Stock',
                  value:
                      '${material.stockActual.toStringAsFixed(0)} ${material.unidad}',
                ),
              ),
              Expanded(
                child: _miniInfo(
                  label: 'Después',
                  value: '${despues.toStringAsFixed(0)} ${material.unidad}',
                  highlight: esInsuficiente,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniInfo({
    required String label,
    required String value,
    bool highlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTypography.caption.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.small.copyWith(
            fontWeight: FontWeight.w600,
            color: highlight ? AppColors.error : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// BADGE DE ESTADO
// ═════════════════════════════════════════════════════════════════════════════
class _BadgeEstado extends StatelessWidget {
  final String estado;
  const _BadgeEstado({required this.estado});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (estado) {
      case 'disponible':
        bg = AppColors.success.withValues(alpha: 0.12);
        fg = AppColors.success;
        label = 'Disponible';
        break;
      case 'justo':
        bg = AppColors.warning.withValues(alpha: 0.15);
        fg = AppColors.warning;
        label = 'Justo';
        break;
      case 'insuficiente':
        bg = AppColors.error.withValues(alpha: 0.12);
        fg = AppColors.error;
        label = 'Insuficiente';
        break;
      default:
        bg = AppColors.neutral100;
        fg = AppColors.textMuted;
        label = estado;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.visible,
        softWrap: false,
      ),
    );
  }
}
