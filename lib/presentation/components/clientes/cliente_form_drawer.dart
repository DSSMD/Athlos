// lib/presentation/components/clientes/cliente_form_page.dart

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import 'cliente_contact_card.dart';
import 'cliente_credit_card.dart';
import 'cliente_error_dialog.dart';
import 'cliente_identification_card.dart';
import 'cliente_preferences_card.dart';
import 'cliente_success_dialog.dart';
import 'cliente_summary_panel.dart';

import '../../models/cliente_mock.dart';
import '../../widgets/loading_spinner.dart';

/// API pública — llamar con `showClienteFormDrawer(context, initialCliente: ...)`.
Future<void> showClienteFormDrawer(
  BuildContext context, {
  ClienteFormMode mode = ClienteFormMode.crear,
  ClienteMock? initialCliente,
}) {
  final isMobile = MediaQuery.of(context).size.width < 900;

  if (isMobile) {
    // Mobile: pantalla completa que sube desde abajo
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false, // Importante para que se vea el fondo oscuro
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) =>
            ClienteFormPage(mode: mode, initialCliente: initialCliente),
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

  // Desktop: drawer lateral derecho con overlay
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, _, _) => Align(
      alignment: Alignment.centerRight,
      child: ClienteFormPage(mode: mode, initialCliente: initialCliente),
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

class ClienteFormPage extends StatefulWidget {
  const ClienteFormPage({
    super.key,
    this.mode = ClienteFormMode.crear,
    this.initialCliente,
  });

  final ClienteFormMode mode;
  final ClienteMock? initialCliente;

  @override
  State<ClienteFormPage> createState() => _ClienteFormPageState();
}

class _ClienteFormPageState extends State<ClienteFormPage> {
  // ───────── Controllers
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
  late bool _facturacionElectronica;

  bool _isSaving = false;
  Map<String, String?> _errors = {};

  // SCRUM-69: keys para scroll-to-error y destello rojo
  final _scrollController = ScrollController();
  final _representanteKey = GlobalKey();
  final _telefonoKey = GlobalKey();
  final _nitCiKey = GlobalKey();
  final _emailKey = GlobalKey();

  String? _flashingField;

  // Simulación: si el C.I. es exactamente "12345678" se trata como duplicado.
  static const String _ciDuplicadoSimulado = '12345678';

  @override
  void initState() {
    super.initState();
    final c = widget.initialCliente;
    _nitCiCtrl = TextEditingController(text: c?.nitCi ?? '');
    _razonSocialCtrl = TextEditingController(text: c?.razonSocial ?? '');
    _representanteCtrl = TextEditingController(
      text: c?.representanteLegal ?? '',
    );
    _telefonoCtrl = TextEditingController(text: c?.telefono ?? '');
    _telefonoSecCtrl = TextEditingController(text: c?.telefonoSecundario ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _direccionCtrl = TextEditingController(text: c?.direccion ?? '');
    _limiteCtrl = TextEditingController(
      text: c != null ? c.limiteCredito.toStringAsFixed(2) : '',
    );
    _diasCtrl = TextEditingController(
      text: c != null ? c.diasPlazoPago.toString() : '30',
    );
    _notasCtrl = TextEditingController(text: c?.notas ?? '');

    _tipoCliente = c?.tipoCliente ?? TipoCliente.empresa;
    _permiteCredito = c?.permiteCredito ?? false;
    _clientePrioritario = c?.clientePrioritario ?? false;
    _facturacionElectronica = c?.facturacionElectronica ?? false;
  }

  @override
  void dispose() {
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

    if (_representanteCtrl.text.trim().isEmpty) {
      errors['representante'] = 'El representante legal es requerido';
    }

    if (_telefonoCtrl.text.trim().isEmpty) {
      errors['telefono'] = 'El teléfono es requerido';
    }

    final ci = _nitCiCtrl.text.trim();
    if (ci.isNotEmpty && !RegExp(r'^[0-9\-]+$').hasMatch(ci)) {
      errors['nitCi'] = 'El NIT/CI debe contener solo números';
    }

    final email = _emailCtrl.text.trim();
    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(email)) {
      errors['email'] = 'Email inválido';
    }

    setState(() => _errors = errors);
    return errors.isEmpty;
  }

  // ───────────────────────────────────── SIMULACIÓN DE GUARDADO ──

  Future<void> _handleGuardar() async {
    if (!_validar()) {
      _mostrarErroresSnackbar();
      _scrollToFirstError();
      return;
    }

    setState(() => _isSaving = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final ci = _nitCiCtrl.text.trim();
    if (ci == _ciDuplicadoSimulado) {
      setState(() => _isSaving = false);
      await showClienteErrorDialog(
        context,
        titulo: 'C.I. duplicado',
        mensaje:
            'Ya existe un cliente registrado con el C.I. $ci. Por favor, '
            'verificá los datos o busca el cliente existente.',
      );
      return;
    }

    setState(() => _isSaving = false);
    await showClienteSuccessDialog(
      context,
      mensaje: widget.mode == ClienteFormMode.crear
          ? 'El cliente fue registrado correctamente en el sistema.'
          : 'Los cambios se guardaron correctamente.',
    );
  }

  // Hace scroll al primer campo con error y lo destella en rojo.
  void _scrollToFirstError() {
    final orderedKeys = [
      ('nitCi', _nitCiKey),
      ('representante', _representanteKey),
      ('telefono', _telefonoKey),
      ('email', _emailKey),
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

  void _mostrarErroresSnackbar() {
    if (_errors.isEmpty) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.neutral950,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        margin: const EdgeInsets.all(AppSpacing.lg),
        content: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Revisá los campos marcados en rojo',
                style: AppTypography.small.copyWith(
                  color: AppColors.brandWhite,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // BUILD PRINCIPAL
  // ══════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    // 1. Detectamos si es móvil para el tamaño
    final isMobile = MediaQuery.of(context).size.width < 900;

    // 2. EL TAMAÑO: 100% en móvil, 500px de ancho en escritorio
    final double formWidth = isMobile ? double.infinity : 600.0;

    // 👇 1. AÑADE ESTE WIDGET 'Material' AQUÍ 👇
    return Material(
      color:
          AppColors.background, // Movemos el color de fondo hacia el Material
      elevation:
          16, // Opcional: Le da una sombra muy elegante a tu Drawer flotante

      child: SizedBox(
        width: formWidth, // Mantenemos el límite de tamaño
        // color: AppColors.background, <-- ⚠️ BORRA el color de aquí porque ya está arriba
        child: SafeArea(
          child: Column(
            children: [
              _Header(
                isEditing: widget.mode == ClienteFormMode.editar,
                onClose: () => Navigator.of(context).pop(),
              ),

              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: _buildFormColumn(),
                ),
              ),

              _Footer(
                isEditing: widget.mode == ClienteFormMode.editar,
                isSaving: _isSaving,
                onCancel: () => Navigator.of(context).pop(),
                onSave: () {
                  if (_validar()) {
                    // Lógica para guardar
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormColumn() {
    return Column(
      children: [
        if (widget.mode == ClienteFormMode.editar &&
            widget.initialCliente != null) ...[
          ClienteSummaryPanel(cliente: widget.initialCliente!),
          const SizedBox(height: AppSpacing.xl),
        ],

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
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _FlashWrap(
          isFlashing: _flashingField == 'telefono' || _flashingField == 'email',
          child: ClienteContactCard(
            key: _telefonoKey,
            telefonoController: _telefonoCtrl,
            telefonoSecController: _telefonoSecCtrl,
            emailController: _emailCtrl,
            direccionController: _direccionCtrl,
            onWhatsappTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Simulación: abrir WhatsApp para ${_telefonoCtrl.text}',
                    style: AppTypography.small,
                  ),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ClienteCreditCard(
          permiteCredito: _permiteCredito,
          onPermiteCreditoChanged: (v) => setState(() => _permiteCredito = v),
          limiteController: _limiteCtrl,
          diasController: _diasCtrl,
          notasController: _notasCtrl,
        ),
        const SizedBox(height: AppSpacing.lg),
        ClientePreferencesCard(
          clientePrioritario: _clientePrioritario,
          onPrioritarioChanged: (v) => setState(() => _clientePrioritario = v),
          facturacionElectronica: _facturacionElectronica,
          onFacturacionChanged: (v) =>
              setState(() => _facturacionElectronica = v),
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
  const _Header({required this.isEditing, required this.onClose});
  final bool isEditing;
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
                  'Usuarios',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
                Text(
                  isEditing ? 'Editar usuario' : 'Nuevo usuario',
                  style: AppTypography.h3,
                ),
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
                  : Text(isEditing ? 'Guardar cambios' : 'Crear usuario'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// _FlashWrap: envuelve un widget y le aplica un destello rojo cuando
// isFlashing = true. Se usa para llamar la atención del usuario al primer
// campo con error tras una validación fallida.
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
