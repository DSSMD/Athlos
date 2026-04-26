// lib/presentation/components/clientes/cliente_form_drawer.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import 'cliente_contact_card.dart';
import 'cliente_credit_card.dart';
import 'cliente_error_dialog.dart';
import 'cliente_identification_card.dart';
import 'cliente_preferences_card.dart';
import 'cliente_resumen_view.dart';
import 'cliente_success_dialog.dart';

import '../../widgets/loading_spinner.dart';

import '../../../domain/models/cliente_model.dart';
import '../../providers/cliente_provider.dart';

/// API pública — llamar con `showClienteFormDrawer(context, initialCliente: ...)`.
Future<void> showClienteFormDrawer(
  BuildContext context, {
  ClienteFormMode mode = ClienteFormMode.crear,
  ClienteModel? initialCliente,
  // 0 = Editar, 1 = Resumen. Solo aplica en modo editar (sino se ignora).
  int initialTab = 0,
}) {
  final isMobile = MediaQuery.of(context).size.width < 900;

  if (isMobile) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) => ClienteFormDrawer(
          mode: mode,
          initialCliente: initialCliente,
          initialTab: initialTab,
        ),
        transitionsBuilder: (_, animation, _, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic)),
            ),
            child: child,
          );
        },
      ),
    );
  }

  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, _, _) => Align(
      alignment: Alignment.centerRight,
      child: ClienteFormDrawer(
        mode: mode,
        initialCliente: initialCliente,
        initialTab: initialTab,
      ),
    ),
    transitionBuilder: (_, animation, _, child) {
      return SlideTransition(
        position: animation.drive(
          Tween(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic)),
        ),
        child: child,
      );
    },
  );
}

class ClienteFormDrawer extends ConsumerStatefulWidget {
  const ClienteFormDrawer({
    super.key,
    this.mode = ClienteFormMode.crear,
    this.initialCliente,
    this.initialTab = 0,
  });

  final ClienteFormMode mode;
  final ClienteModel? initialCliente;
  final int initialTab;

  @override
  ConsumerState<ClienteFormDrawer> createState() => _ClienteFormDrawerState();
}

class _ClienteFormDrawerState extends ConsumerState<ClienteFormDrawer>
    with SingleTickerProviderStateMixin {
  // ───────── Tabs (solo en modo editar)
  TabController? _tabController;
  bool get _showTabs => widget.mode == ClienteFormMode.editar;

  // ───────── Controllers de texto
  late final TextEditingController _nitCiCtrl;
  late final TextEditingController _razonSocialCtrl;
  late final TextEditingController _representanteCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _telefonoSecCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _direccionCtrl;
  late final TextEditingController _limiteCtrl;
  late final TextEditingController _diasCtrl;
  late final TextEditingController _notasCtrl;

  // ───────── Estado
  late TipoCliente _tipoCliente;
  late bool _permiteCredito;
  late bool _clientePrioritario;

  bool _isSaving = false;
  Map<String, String?> _errors = {};
  String? _bannerError; // Mensaje de error general visible arriba del form

  final _scrollController = ScrollController();
  final _representanteKey = GlobalKey();
  final _telefonoKey = GlobalKey();
  final _nitCiKey = GlobalKey();
  final _emailKey = GlobalKey();
  final _creditoKey = GlobalKey();

  String? _flashingField;

  @override
  void initState() {
    super.initState();
    final c = widget.initialCliente;

    // Mapeo de datos reales al iniciar
    _nitCiCtrl = TextEditingController(text: c?.ciCliente ?? '');
    _razonSocialCtrl = TextEditingController(text: c?.razonSocial ?? '');
    final nombreCompleto = c != null
        ? '${c.nomCliente} ${c.apellidoCliente}'.trim()
        : '';
    _representanteCtrl = TextEditingController(text: nombreCompleto);

    _telefonoCtrl = TextEditingController(text: c?.numTelefono ?? '');
    _telefonoSecCtrl = TextEditingController(text: c?.numTelefono2 ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _direccionCtrl = TextEditingController(text: c?.direccion ?? '');
    _limiteCtrl = TextEditingController(
      text: c != null && c.limiteCredito > 0
          ? c.limiteCredito.toStringAsFixed(2)
          : '',
    );
    _diasCtrl = TextEditingController(
      text: c != null ? c.diasPlazoPago.toString() : '30',
    );
    _notasCtrl = TextEditingController(text: c?.notas ?? '');

    _tipoCliente = c?.tipoEnum ?? TipoCliente.empresa;
    _permiteCredito = c?.permiteCredito ?? false;
    _clientePrioritario = c?.esPrioritario ?? false;

    // Inicializar tabs solo si estamos en modo editar
    if (_showTabs) {
      _tabController = TabController(
        length: 2,
        vsync: this,
        initialIndex: widget.initialTab.clamp(0, 1),
      );
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _scrollController.dispose();
    _nitCiCtrl.dispose();
    _razonSocialCtrl.dispose();
    _representanteCtrl.dispose();
    _telefonoCtrl.dispose();
    _telefonoSecCtrl.dispose();
    _emailCtrl.dispose();
    _direccionCtrl.dispose();
    _limiteCtrl.dispose();
    _diasCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  // ───────────────────────────────────────── VALIDACIÓN LOCAL ──
  bool _validar() {
    final errors = <String, String?>{};

    // 1. Representante/Nombre — requerido
    if (_representanteCtrl.text.trim().isEmpty) {
      errors['representante'] = 'El representante/nombre es requerido';
    }

    // 2. Razón social — requerida si tipo es Empresa
    if (_tipoCliente == TipoCliente.empresa &&
        _razonSocialCtrl.text.trim().isEmpty) {
      errors['razonSocial'] = 'La razón social es requerida para empresas';
    }

    // 3. Teléfono — requerido + mínimo 8 dígitos
    final telefono = _telefonoCtrl.text.trim();
    if (telefono.isEmpty) {
      errors['telefono'] = 'El teléfono es requerido';
    } else if (telefono.replaceAll(RegExp(r'\s+'), '').length < 8) {
      errors['telefono'] = 'El número parece ser muy corto';
    }

    // 4. NIT/CI — si se llena, solo números o guiones
    final ci = _nitCiCtrl.text.trim();
    if (ci.isNotEmpty && !RegExp(r'^[0-9\-]+$').hasMatch(ci)) {
      errors['nitCi'] = 'El NIT/CI debe contener solo números o guiones';
    }

    // 5. Email — si se llena, formato válido
    final email = _emailCtrl.text.trim();
    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(email)) {
      errors['email'] = 'Email inválido';
    }

    // 6. Si crédito activo: límite y días deben ser > 0
    if (_permiteCredito) {
      final limite = double.tryParse(_limiteCtrl.text) ?? 0.0;
      if (limite <= 0) {
        errors['limite'] = 'El límite de crédito debe ser mayor a 0';
      }
      final dias = int.tryParse(_diasCtrl.text) ?? 0;
      if (dias <= 0) {
        errors['dias'] = 'Los días de plazo deben ser mayor a 0';
      }
    }

    setState(() => _errors = errors);
    return errors.isEmpty;
  }

  // ───────────────────────────────────────── FORMATEO DE TELÉFONO ──
  String _formatearTelefono(String numero) {
    String tel = numero.trim();
    if (tel.isEmpty) return '';
    tel = tel.replaceAll(RegExp(r'\s+'), '');
    if (tel.startsWith('+591')) return tel;
    if (tel.startsWith('591')) return '+$tel';
    return '+591 $tel';
  }

  // ───────────────────────────────────── GUARDADO REAL EN BD ──
  Future<void> _handleGuardar() async {
    if (!_validar()) {
      _mostrarBannerError();
      _scrollToFirstError();
      return;
    }

    setState(() => _isSaving = true);

    final nombreParts = _representanteCtrl.text.trim().split(' ');
    final nombre = nombreParts.isNotEmpty ? nombreParts.first : '';
    final apellido = nombreParts.length > 1
        ? nombreParts.sublist(1).join(' ')
        : '';
    final isEmpresa = _tipoCliente == TipoCliente.empresa;

    // NOTA: si está vacío enviamos string vacío (no "S/N") para evitar
    // duplicados en BD. Den/backend deciden cómo manejarlo.
    final ciLimpio = _nitCiCtrl.text.trim();

    final razonLimpia = _razonSocialCtrl.text.trim().isEmpty
        ? ''
        : _razonSocialCtrl.text.trim();
    final emailLimpio = _emailCtrl.text.trim().isEmpty
        ? ''
        : _emailCtrl.text.trim();
    final dirLimpia = _direccionCtrl.text.trim().isEmpty
        ? 'Sin dirección'
        : _direccionCtrl.text.trim();
    final notasLimpias = _notasCtrl.text.trim().isEmpty
        ? ''
        : _notasCtrl.text.trim();

    final clienteGuardar = ClienteModel(
      idCliente: widget.initialCliente?.idCliente,
      ciCliente: ciLimpio,
      nomCliente: nombre,
      apellidoCliente: apellido,
      razonSocial: isEmpresa ? razonLimpia : '',
      email: emailLimpio,
      numTelefono: _formatearTelefono(_telefonoCtrl.text),
      numTelefono2: _formatearTelefono(_telefonoSecCtrl.text),
      direccion: dirLimpia,
      idTipoCliente: isEmpresa ? 1 : 2,
      permiteCredito: _permiteCredito,
      limiteCredito: double.tryParse(_limiteCtrl.text) ?? 0.0,
      diasPlazoPago: int.tryParse(_diasCtrl.text) ?? 30,
      esPrioritario: _clientePrioritario,
      notas: notasLimpias,
    );

    try {
      if (widget.mode == ClienteFormMode.crear) {
        await ref
            .read(clientesProvider.notifier)
            .registrarCliente(clienteGuardar);
      } else {
        await ref
            .read(clientesProvider.notifier)
            .actualizarCliente(clienteGuardar);
      }

      final estadoProvider = ref.read(clientesProvider);
      if (estadoProvider.hasError) {
        throw Exception(estadoProvider.error);
      }

      if (!mounted) return;
      Navigator.of(context).pop();

      await showClienteSuccessDialog(
        context,
        mensaje: widget.mode == ClienteFormMode.crear
            ? 'El cliente fue registrado correctamente en el sistema.'
            : 'Los cambios se guardaron correctamente.',
      );
    } catch (e) {
      if (!mounted) return;
      await showClienteErrorDialog(
        context,
        titulo: 'Error al guardar',
        mensaje: e.toString().replaceAll('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _scrollToFirstError() {
    final orderedKeys = [
      ('nitCi', _nitCiKey),
      ('representante', _representanteKey),
      ('razonSocial', _representanteKey), // misma key — está en el mismo card
      ('telefono', _telefonoKey),
      ('email', _emailKey),
      ('limite', _creditoKey),
      ('dias', _creditoKey),
    ];

    for (final (errorKey, widgetKey) in orderedKeys) {
      if (_errors.containsKey(errorKey)) {
        final ctx = widgetKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            alignment: 0.2,
          );
          _flashField(errorKey);
        }
        break;
      }
    }
  }

  void _flashField(String fieldKey) {
    setState(() => _flashingField = fieldKey);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() => _flashingField = null);
    });
  }

  void _mostrarBannerError() {
    if (_errors.isEmpty) return;
    setState(() {
      _bannerError = 'Revisá los campos marcados en rojo';
    });
    // Auto-ocultar tras 4 segundos
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _bannerError = null);
    });
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // BUILD PRINCIPAL
  // ══════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    // Ancho: en modo editar usamos 700 para acomodar mejor el contenido
    // del tab Resumen. En crear queda en 600 (más cómodo para el form).
    final double formWidth = isMobile
        ? double.infinity
        : (_showTabs ? 700.0 : 600.0);

    return Material(
      color: AppColors.background,
      elevation: 16,
      child: SizedBox(
        width: formWidth,
        child: SafeArea(
          child: Column(
            children: [
              // Header dinámico: en modo editar el título cambia según el tab activo.
              if (_showTabs && _tabController != null)
                AnimatedBuilder(
                  animation: _tabController!,
                  builder: (context, _) {
                    final title = _tabController!.index == 0
                        ? 'Editar cliente'
                        : 'Detalle del cliente';
                    return _Header(
                      title: title,
                      onClose: () => Navigator.of(context).pop(),
                    );
                  },
                )
              else
                _Header(
                  title: 'Nuevo cliente',
                  onClose: () => Navigator.of(context).pop(),
                ),

              // Banner de error general (debajo del header, encima del contenido)
              if (_bannerError != null) _ErrorBanner(message: _bannerError!),

              // Si estamos en modo editar, mostramos los tabs
              if (_showTabs && _tabController != null) ...[
                Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppColors.border)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary500,
                    unselectedLabelColor: AppColors.textMuted,
                    indicatorColor: AppColors.primary500,
                    indicatorWeight: 2,
                    labelStyle: AppTypography.small.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: AppTypography.small,
                    tabs: const [
                      Tab(text: 'Editar'),
                      Tab(text: 'Resumen'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Tab Editar
                      SingleChildScrollView(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: _buildFormColumn(),
                      ),
                      // Tab Resumen
                      SingleChildScrollView(
                        child: ClienteResumenView(
                          cliente: widget.initialCliente!,
                        ),
                      ),
                    ],
                  ),
                ),

                // Footer dinámico según el tab activo
                AnimatedBuilder(
                  animation: _tabController!,
                  builder: (context, _) {
                    if (_tabController!.index == 0) {
                      return _Footer(
                        isEditing: true,
                        isSaving: _isSaving,
                        onCancel: () => Navigator.of(context).pop(),
                        onSave: _handleGuardar,
                      );
                    }
                    // Tab Resumen: solo botón Cerrar
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: AppSpacing.lg,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.border),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cerrar'),
                        ),
                      ),
                    );
                  },
                ),
              ] else ...[
                // Modo crear: sin tabs, formulario directo
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: _buildFormColumn(),
                  ),
                ),
                _Footer(
                  isEditing: false,
                  isSaving: _isSaving,
                  onCancel: () => Navigator.of(context).pop(),
                  onSave: _handleGuardar,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormColumn() {
    return Column(
      children: [
        // 1. IDENTIFICACIÓN
        _FlashWrap(
          isFlashing:
              _flashingField == 'nitCi' || _flashingField == 'representante',
          child: ClienteIdentificationCard(
            key: _representanteKey,
            nitCiController: _nitCiCtrl,
            razonSocialController: _razonSocialCtrl,
            representanteController: _representanteCtrl,
            tipoCliente: _tipoCliente,
            onTipoChanged: (v) => setState(() => _tipoCliente = v),
            errors: _errors,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 2. CONTACTO
        _FlashWrap(
          isFlashing: _flashingField == 'telefono' || _flashingField == 'email',
          child: ClienteContactCard(
            key: _telefonoKey,
            telefonoController: _telefonoCtrl,
            telefonoSecController: _telefonoSecCtrl,
            emailController: _emailCtrl,
            direccionController: _direccionCtrl,
            errors: _errors,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 3. CRÉDITO
        _FlashWrap(
          isFlashing: _flashingField == 'limite' || _flashingField == 'dias',
          child: ClienteCreditCard(
            key: _creditoKey,
            permiteCredito: _permiteCredito,
            onPermiteCreditoChanged: (v) => setState(() => _permiteCredito = v),
            limiteController: _limiteCtrl,
            diasController: _diasCtrl,
            notasController: _notasCtrl,
            errors: _errors,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 4. PREFERENCIAS
        ClientePreferencesCard(
          clientePrioritario: _clientePrioritario,
          onPrioritarioChanged: (v) => setState(() => _clientePrioritario = v),
        ),
        const SizedBox(height: AppSpacing.xl3),
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HEADER
// ══════════════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Clientes',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                Text(title, style: AppTypography.h3),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close),
            color: AppColors.textSecondary,
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// FOOTER
// ══════════════════════════════════════════════════════════════════════════════

class _Footer extends StatelessWidget {
  const _Footer({
    required this.onCancel,
    required this.onSave,
    required this.isEditing,
    this.isSaving = false,
  });

  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool isEditing;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: isSaving ? null : onCancel,
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: isSaving ? null : onSave,
              child: isSaving
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LoadingSpinner(
                          size: LoadingSize.sm,
                          color: AppColors.brandWhite,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(isEditing ? 'Guardando...' : 'Creando...'),
                      ],
                    )
                  : Text(isEditing ? 'Guardar cambios' : 'Crear cliente'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// _FlashWrap: destello rojo al primer campo con error.
// ============================================================================
class _FlashWrap extends StatelessWidget {
  const _FlashWrap({required this.child, required this.isFlashing});

  final Widget child;
  final bool isFlashing;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: isFlashing
            ? [
                BoxShadow(
                  color: AppColors.error.withValues(alpha: 0.4),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ]
            : [],
      ),
      child: child,
    );
  }
}

// ============================================================================
// _ErrorBanner: banner rojo dentro del drawer para mostrar errores generales.
// Se usa en lugar de SnackBar porque el SnackBar global queda detrás del drawer.
// ============================================================================
class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.small.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
