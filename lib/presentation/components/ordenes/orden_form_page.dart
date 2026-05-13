// ============================================================================
// orden_form_page.dart
// Ubicación: lib/presentation/components/ordenes/orden_form_page.dart
// Descripción: Contenedor de la pantalla "Nueva orden".
// Maneja el state local del OrdenDraft y compone los cards en un layout de
// 2 columnas (desktop) / stack vertical (mobile).
//
// Refactor (esquema nuevo):
//   - Validación pasa de _draft.esValido (legacy / draft.productos) a
//     _draft.esValidoItems (draft.items).
//   - Submit usa _draft.items vía ordenServiceProvider.crearOrdenDesdeDraft.
//     NOTA: ese método está stubbed con UnimplementedError hasta que se
//     implemente la RPC en Supabase — esto está OK, el form ya queda
//     estructuralmente correcto y el error se muestra en SnackBar.
//   - Se elimina _handleRecalcularMateriales y OrdenMaterialesCard del layout
//     (cálculo de materiales out-of-scope per stakeholder; precios se ingresan
//     manualmente por ítem dentro del AgregarItemDialog).
//   - Se elimina _prevProductCount y el auto-recálculo asociado.
// ============================================================================

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/orden_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import 'orden_anticipo_card.dart';
import 'orden_calendario_card.dart';
import 'orden_draft.dart';
import 'orden_info_card.dart';
import 'orden_prioridad_card.dart';
import 'orden_productos_card.dart';
import 'orden_resumen_card.dart';

class OrdenFormPage extends ConsumerStatefulWidget {
  final VoidCallback onVolver;
  const OrdenFormPage({super.key, required this.onVolver});

  @override
  ConsumerState<OrdenFormPage> createState() => _OrdenFormPageState();
}

class _OrdenFormPageState extends ConsumerState<OrdenFormPage> {
  OrdenDraft _draft = OrdenDraft.empty();

  void _updateDraft(OrdenDraft nuevo) {
    setState(() => _draft = nuevo);
  }

  void _onCancelar() {
    // TODO(SCRUM-75): si el draft tiene cambios, mostrar diálogo de confirmación
    widget.onVolver();
  }

  void _onGuardarBorrador() {
    // TODO: cache local opcional. Por ahora stub.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Guardar borrador — funcionalidad en desarrollo'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _onCrearOrden() async {
    if (!_draft.esValidoItems) return;

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Creando orden...'),
          duration: Duration(seconds: 1),
        ),
      );

      final servicio = ref.read(ordenServiceProvider);
      await servicio.crearOrdenDesdeDraft(_draft);

      ref.read(ordenesProvider.notifier).refreshOrdenes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Orden creada exitosamente!'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onVolver();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
              esValido: _draft.esValidoItems,
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

  // ─── LAYOUT DESKTOP ───
  Widget _buildDesktop() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              OrdenInfoCard(draft: _draft, onChanged: _updateDraft),
              const SizedBox(height: AppSpacing.lg),
              OrdenProductosCard(draft: _draft, onChanged: _updateDraft),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
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

  // ─── LAYOUT MOBILE ───
  Widget _buildMobile() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OrdenInfoCard(draft: _draft, onChanged: _updateDraft),
        const SizedBox(height: AppSpacing.lg),
        OrdenProductosCard(draft: _draft, onChanged: _updateDraft),
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

// ─── HEADER ───
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
