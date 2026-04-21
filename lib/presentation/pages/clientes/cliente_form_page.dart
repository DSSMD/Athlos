// ============================================================================
// cliente_form_page.dart
// Ubicación: lib/presentation/pages/clientes/cliente_form_page.dart
// Descripción: Página principal de Crear / Editar Cliente.
// Orquesta los 4 cards del formulario + panel lateral (solo modo editar) +
// validaciones locales + simulación de estados (loading, éxito, error).
//
// Uso:
//   ClienteFormPage(mode: ClienteFormMode.crear)
//   ClienteFormPage(mode: ClienteFormMode.editar, initialCliente: ejemploClienteMaria())
//
// @denshel: Esta pantalla hoy NO conecta a Supabase — simula los estados con
// Future.delayed. Al integrar, reemplazar `_handleGuardar` por la llamada real.
// ============================================================================

import 'package:flutter/material.dart';
import '../../components/clientes/cliente_contact_card.dart';
import '../../components/clientes/cliente_credit_card.dart';
import '../../components/clientes/cliente_error_dialog.dart';
import '../../components/clientes/cliente_identification_card.dart';
import '../../components/clientes/cliente_preferences_card.dart';
import '../../components/clientes/cliente_success_dialog.dart';
import '../../components/clientes/cliente_summary_panel.dart';
import '../../models/cliente_mock.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/loading_spinner.dart';

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
    _representanteCtrl = TextEditingController(text: c?.representanteLegal ?? '');
    _telefonoCtrl = TextEditingController(text: c?.telefono ?? '');
    _telefonoSecCtrl = TextEditingController(text: c?.telefonoSecundario ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _direccionCtrl = TextEditingController(text: c?.direccion ?? '');
    _limiteCtrl = TextEditingController(
        text: c != null ? c.limiteCredito.toStringAsFixed(2) : '');
    _diasCtrl = TextEditingController(
        text: c != null ? c.diasPlazoPago.toString() : '30');
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
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 20),
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

  // ───────────────────────────────────────────────────── UI ──

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 1024;
    final isEditar = widget.mode == ClienteFormMode.editar;
    final mostrarPanel = isEditar && widget.initialCliente != null;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          _buildTopbar(isEditar),
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: isMobile
                  ? _buildMobileLayout(mostrarPanel)
                  : _buildDesktopLayout(mostrarPanel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopbar(bool isEditar) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    // TODO @denshel: este patrón (topbar blanco en desktop / negro en mobile)
    // se repite en UI-02 y SCRUM-69. Al extraer el Shell adaptativo,
    // considerá crear un AppTopbar reutilizable con variantes configurables.

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: isMobile ? AppColors.neutral950 : AppColors.brandWhite,
        border: isMobile
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: isMobile
          ? _buildTopbarMobile(isEditar)
          : _buildTopbarDesktop(isEditar),
    );
  }

  Widget _buildTopbarDesktop(bool isEditar) {
    return Row(
      children: [
        Expanded(child: _buildBreadcrumb(isEditar, isMobile: false)),
        _buildCancelButton(isMobile: false),
        const SizedBox(width: AppSpacing.md),
        _buildSaveButton(isEditar, isMobile: false),
      ],
    );
  }

  Widget _buildTopbarMobile(bool isEditar) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildBreadcrumb(isEditar, isMobile: true),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _buildCancelButton(isMobile: true)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: _buildSaveButton(isEditar, isMobile: true)),
          ],
        ),
      ],
    );
  }

  Widget _buildBreadcrumb(bool isEditar, {required bool isMobile}) {
    if (isMobile) {
      return Row(
        children: [
          InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            child: Row(
              children: [
                const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.primary500,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  'Clientes',
                  style: AppTypography.small.copyWith(
                    color: AppColors.primary500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              isEditar ? 'Editar cliente' : 'Nuevo cliente',
              style: AppTypography.body.copyWith(
                color: AppColors.brandWhite,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          const SizedBox(width: 80),
        ],
      );
    }

    return Row(
      children: [
        Flexible(
          child: Text(
            'Clientes',
            style: AppTypography.body.copyWith(color: AppColors.textMuted),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Text('/'),
        ),
        Flexible(
          child: Text(
            isEditar ? 'Editar cliente' : 'Nuevo cliente',
            style: AppTypography.h3.copyWith(color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCancelButton({required bool isMobile}) {
    return OutlinedButton(
      onPressed: _isSaving ? null : () => Navigator.of(context).maybePop(),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        side: BorderSide(
          color: isMobile ? AppColors.neutral600 : AppColors.border,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      child: Text(
        'Cancelar',
        style: AppTypography.small.copyWith(
          color: isMobile ? AppColors.brandWhite : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isEditar, {required bool isMobile}) {
    return ElevatedButton(
      onPressed: _isSaving ? null : _handleGuardar,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary500,
        foregroundColor: AppColors.brandWhite,
        disabledBackgroundColor: AppColors.primary200,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        elevation: 0,
      ),
      child: _isSaving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: LoadingSpinner(size: LoadingSize.sm),
            )
          : Text(
              isEditar ? 'Guardar cambios' : 'Crear cliente',
              style: AppTypography.small.copyWith(
                color: AppColors.brandWhite,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
    );
  }

  Widget _buildDesktopLayout(bool mostrarPanel) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildFormColumn(),
        ),
        if (mostrarPanel) ...[
          const SizedBox(width: AppSpacing.xl),
          Expanded(
            flex: 1,
            child: ClienteSummaryPanel(cliente: widget.initialCliente!),
          ),
        ],
      ],
    );
  }

  Widget _buildMobileLayout(bool mostrarPanel) {
    return Column(
      children: [
        if (mostrarPanel) ...[
          ClienteSummaryPanel(cliente: widget.initialCliente!),
          const SizedBox(height: AppSpacing.xl),
        ],
        _buildFormColumn(),
      ],
    );
  }

  Widget _buildFormColumn() {
    return Column(
      children: [
        _FlashWrap(
          isFlashing: _flashingField == 'nitCi' ||
              _flashingField == 'representante',
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
          isFlashing: _flashingField == 'telefono' ||
              _flashingField == 'email',
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