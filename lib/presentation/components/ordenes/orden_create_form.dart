// ============================================================================
// orden_create_form.dart
// Ubicación: lib/presentation/components/ordenes/orden_create_form.dart
// Descripción: Contenedor de la pantalla "Nueva orden" (SCRUM-75).
// Maneja el state local del OrdenDraft y compone los cards del Figma
// en un layout de 2 columnas (desktop) / stack vertical (mobile).
//
// Bloque 1: solo header + grid vacío. Cards se agregan en bloques siguientes.
// ============================================================================

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import 'orden_draft.dart';
import 'orden_info_card.dart';
import 'orden_productos_card.dart';
import 'orden_materiales_card.dart';
import 'orden_resumen_card.dart';
import 'orden_prioridad_card.dart';
import 'orden_anticipo_card.dart';
import 'orden_calendario_card.dart';

class OrdenCreateForm extends StatefulWidget {
  /// Callback cuando el usuario cancela o termina de crear.
  final VoidCallback onVolver;

  const OrdenCreateForm({super.key, required this.onVolver});

  @override
  State<OrdenCreateForm> createState() => _OrdenCreateFormState();
}

class _OrdenCreateFormState extends State<OrdenCreateForm> {
  OrdenDraft _draft = OrdenDraft.empty();

  // ignore: unused_element
  void _updateDraft(OrdenDraft nuevo) {
    setState(() => _draft = nuevo);
  }

  void _onCancelar() {
    // TODO(SCRUM-75): si el draft tiene cambios, mostrar diálogo de confirmación
    widget.onVolver();
  }

  void _onGuardarBorrador() {
    // TODO(SCRUM-75): cache local opcional. Por ahora stub.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Guardar borrador — funcionalidad en desarrollo'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onCrearOrden() {
    if (!_draft.esValido) return;
    // TODO(SCRUM-75): cuando Mel exponga orden_provider.crear(draft),
    // reemplazar el SnackBar por la llamada real.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Orden creada (mock — pendiente conexión a BD)'),
        backgroundColor: AppColors.success,
        duration: Duration(seconds: 2),
      ),
    );
    widget.onVolver();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        return Column(
          children: [
            _Header(
              isMobile: isMobile,
              esValido: _draft.esValido,
              onCancelar: _onCancelar,
              onGuardarBorrador: _onGuardarBorrador,
              onCrearOrden: _onCrearOrden,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                  isMobile ? AppSpacing.lg : AppSpacing.xl2,
                ),
                child: isMobile ? _buildMobile() : _buildDesktop(),
              ),
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYOUT DESKTOP — 2 columnas: principal (flex 2) + lateral (flex 1)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDesktop() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Columna principal
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OrdenInfoCard(draft: _draft, onChanged: _updateDraft),
              const SizedBox(height: AppSpacing.lg),
              OrdenProductosCard(draft: _draft, onChanged: _updateDraft),
              const SizedBox(height: AppSpacing.lg),
              OrdenMaterialesCard(draft: _draft, onChanged: _updateDraft),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        // Columna lateral
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OrdenResumenCard(draft: _draft),
              const SizedBox(height: AppSpacing.lg),
              OrdenCalendarioCard(draft: _draft),
              const SizedBox(height: AppSpacing.lg),
              OrdenPrioridadCard(draft: _draft, onChanged: _updateDraft),
              const SizedBox(height: AppSpacing.lg),
              OrdenAnticipoCard(draft: _draft, onChanged: _updateDraft),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LAYOUT MOBILE — stack vertical, todas las cards una abajo de la otra
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildMobile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OrdenInfoCard(draft: _draft, onChanged: _updateDraft),
        const SizedBox(height: AppSpacing.lg),
        OrdenProductosCard(draft: _draft, onChanged: _updateDraft),
        const SizedBox(height: AppSpacing.lg),
        OrdenMaterialesCard(draft: _draft, onChanged: _updateDraft),
        const SizedBox(height: AppSpacing.lg),
        OrdenResumenCard(draft: _draft),
        const SizedBox(height: AppSpacing.lg),
        OrdenCalendarioCard(draft: _draft),
        const SizedBox(height: AppSpacing.lg),
        OrdenPrioridadCard(draft: _draft, onChanged: _updateDraft),
        const SizedBox(height: AppSpacing.lg),
        OrdenAnticipoCard(draft: _draft, onChanged: _updateDraft),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HEADER — título "Órdenes / Nueva orden" + 3 botones del Figma
// ═══════════════════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final bool isMobile;
  final bool esValido;
  final VoidCallback onCancelar;
  final VoidCallback onGuardarBorrador;
  final VoidCallback onCrearOrden;

  const _Header({
    required this.isMobile,
    required this.esValido,
    required this.onCancelar,
    required this.onGuardarBorrador,
    required this.onCrearOrden,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.lg : AppSpacing.xl2,
        vertical: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: isMobile ? _buildMobile() : _buildDesktop(),
    );
  }

  Widget _buildDesktop() {
    return Row(
      children: [
        // Breadcrumb-ish del Figma: "Órdenes / Nueva orden"
        Text(
          'Órdenes / ',
          style: AppTypography.body.copyWith(color: AppColors.textMuted),
        ),
        Text('Nueva orden', style: AppTypography.h2),
        const Spacer(),
        TextButton(onPressed: onCancelar, child: const Text('Cancelar')),
        const SizedBox(width: AppSpacing.sm),
        OutlinedButton(
          onPressed: onGuardarBorrador,
          child: const Text('Guardar borrador'),
        ),
        const SizedBox(width: AppSpacing.sm),
        ElevatedButton(
          onPressed: esValido ? onCrearOrden : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary500,
            foregroundColor: Colors.white,
          ),
          child: const Text('Crear orden'),
        ),
      ],
    );
  }

  Widget _buildMobile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Órdenes / ',
          style: AppTypography.small.copyWith(color: AppColors.textMuted),
        ),
        Text('Nueva orden', style: AppTypography.h3),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: onCancelar,
                child: const Text('Cancelar'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton(
                onPressed: onGuardarBorrador,
                child: const Text('Borrador'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton(
                onPressed: esValido ? onCrearOrden : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary500,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Crear'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
