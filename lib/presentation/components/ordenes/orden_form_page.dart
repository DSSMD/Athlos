// ============================================================================
// orden_form_page.dart
// Ubicación: lib/presentation/components/ordenes/orden_form_page.dart
// Descripción: Contenedor de la pantalla "Nueva orden" (SCRUM-75).
// Maneja el state local del OrdenDraft y compone los cards del Figma
// en un layout de 2 columnas (desktop) / stack vertical (mobile).
//
// Bloque 1: solo header + grid vacío. Cards se agregan en bloques siguientes.
// ============================================================================

// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../theme/breakpoints.dart';

import 'orden_draft.dart';
import 'orden_info_card.dart';
import 'orden_productos_card.dart';
import 'orden_materiales_card.dart';
import 'orden_resumen_card.dart';
import 'orden_prioridad_card.dart';
import 'orden_anticipo_card.dart';
import 'orden_calendario_card.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/orden_provider.dart';

class OrdenFormPage extends ConsumerStatefulWidget {
  final VoidCallback onVolver;
  const OrdenFormPage({super.key, required this.onVolver});

  @override
  ConsumerState<OrdenFormPage> createState() => _OrdenFormPageState();
}

class _OrdenFormPageState extends ConsumerState<OrdenFormPage> {
  OrdenDraft _draft = OrdenDraft.empty();
  int _prevProductCount = 0;

  void _updateDraft(OrdenDraft nuevo) {
    final productosChanged = nuevo.productos.length != _prevProductCount;
    setState(() => _draft = nuevo);

    // Auto-recalcular materiales cuando se agregan/quitan productos
    if (productosChanged && nuevo.productos.isNotEmpty) {
      _prevProductCount = nuevo.productos.length;
      _handleRecalcularMateriales(silent: true);
    }
  }

  // Método para llamar a la calculadora de Supabase
  // silent=true suprime los SnackBars (para auto-recálculo al agregar producto)
  void _handleRecalcularMateriales({bool silent = false}) async {
    // Verificamos que haya productos antes de calcular
    if (_draft.productos.isEmpty) {
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Añade al menos un producto para calcular materiales.',
            ),
          ),
        );
      }
      return;
    }

    try {
      final service = ref.read(ordenServiceProvider);

      // 1. Calculamos la tabla de materiales
      final nuevosMateriales = await service.calcularMaterialesNecesarios(
        _draft.productos,
      );

      // 2. Calculamos los precios sugeridos para el Resumen
      final productosConPrecio = await service.calcularPreciosSugeridos(
        _draft.productos,
      );

      // 3. Actualizamos el estado de la pantalla
      if (mounted) {
        setState(() {
          _draft = _draft.copyWith(
            materiales: nuevosMateriales,
            productos: productosConPrecio,
          );
        });
      }

      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Materiales calculados correctamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al calcular: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  Future<void> _onCrearOrden() async {
    if (!_draft.esValido) return;

    try {
      // 1. Mostramos indicador de carga (opcional)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Creando orden...'),
          duration: Duration(seconds: 1),
        ),
      );

      // 2. Llamamos a Supabase a través de nuestro Provider
      final servicio = ref.read(ordenServiceProvider);
      await servicio.crearOrdenDesdeDraft(_draft);

      // 3. ¡Éxito! Refrescamos la tabla de atrás y mostramos mensaje
      ref.read(ordenesProvider.notifier).refreshOrdenes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Orden creada exitosamente!'),
            backgroundColor: AppColors.success,
          ),
        );
        widget.onVolver(); // Cerramos el formulario
      }
    } catch (e) {
      // ignore: duplicate_ignore
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Migrated to AppBreakpoints.mobile (1100). Was previously: 900.
    final isMobile = context.isMobile;
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
            padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl2),
            child: isMobile ? _buildMobile() : _buildDesktop(),
          ),
        ),
      ],
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

              // 🔥 AQUÍ CONECTAMOS LA CALCULADORA REAL
              OrdenMaterialesCard(
                draft: _draft,
                onChanged: _updateDraft,
                onRecalcular: _handleRecalcularMateriales,
              ),
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
        OrdenMaterialesCard(
          draft: _draft,
          onChanged: _updateDraft,
          onRecalcular: _handleRecalcularMateriales,
        ),
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
