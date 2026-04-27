// ============================================================================
// orden_materiales_card.dart
// Ubicación: lib/presentation/components/ordenes/orden_materiales_card.dart
// Descripción: Card "Materiales requeridos (calculadora)" del form Crear
// Orden (SCRUM-75). Muestra los materiales necesarios con stock actual y
// estado (disponible / justo / insuficiente). Incluye banner de alerta si
// algún material es insuficiente.
//
// MOCK FIJO: los 4 materiales siempre se muestran tal como en el Figma.
// TODO(SCRUM-75): cuando exista tabla `material` y relación
// `producto_material` en BD, calcular dinámicamente desde productos.
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

  // ═══════════════════════════════════════════════════════════════════════════
  // MOCK FIJO — los 4 materiales del Figma. Se reemplaza cuando exista
  // relación producto→material en BD.
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
    // Por ahora "recalcular" simplemente refresca con los mismos mocks.
    // TODO(SCRUM-75): cuando haya relación con productos reales, este botón
    // dispara el cálculo dinámico.
    onChanged(draft.copyWith(materiales: _materialesMock));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    // Si el draft no tiene materiales aún, los inicializamos con el mock.
    // (Permite que la card siempre muestre algo, fiel al Figma.)
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
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _header(),
          const SizedBox(height: AppSpacing.lg),
          _tabla(materiales),
          if (hayInsuficiente) ...[
            const SizedBox(height: AppSpacing.lg),
            _bannerAlerta(materialInsuficiente),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER — título + botón Recalcular
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _header() {
    return Row(
      children: [
        Expanded(
          child: Text(
            'Materiales requeridos (calculadora)',
            style: AppTypography.h3,
          ),
        ),
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
  // TABLA
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _tabla(List<OrdenMaterialRequerido> materiales) {
    return Column(
      children: [
        _headerTabla(),
        const Divider(height: 1, color: AppColors.border),
        for (var i = 0; i < materiales.length; i++) ...[
          _MaterialRow(material: materiales[i]),
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
  // BANNER DE ALERTA
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
// FILA DE MATERIAL
// ═════════════════════════════════════════════════════════════════════════════
class _MaterialRow extends StatelessWidget {
  final OrdenMaterialRequerido material;
  const _MaterialRow({required this.material});

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
              esInsuficiente
                  ? '${despues.toStringAsFixed(0)} ${material.unidad}'
                  : '${despues.toStringAsFixed(0)} ${material.unidad}',
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

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
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
        ),
      ),
    );
  }
}
