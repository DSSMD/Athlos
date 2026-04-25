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
import 'cliente_success_dialog.dart';
//import 'cliente_summary_panel.dart';

import '../../widgets/loading_spinner.dart';

import '../../../domain/models/cliente_model.dart';
import '../../providers/cliente_provider.dart';

/// API pública — llamar con `showClienteFormDrawer(context, initialCliente: ...)`.
Future<void> showClienteFormDrawer(
  BuildContext context, {
  ClienteFormMode mode = ClienteFormMode.crear,
  ClienteModel? initialCliente, // 👈 Usa el modelo real
}) {
  final isMobile = MediaQuery.of(context).size.width < 900;

  if (isMobile) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) =>
            ClienteFormDrawer(mode: mode, initialCliente: initialCliente),
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
      child: ClienteFormDrawer(mode: mode, initialCliente: initialCliente),
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

// 2. CAMBIO A CONSUMER PARA USAR RIVERPOD
class ClienteFormDrawer extends ConsumerStatefulWidget {
  const ClienteFormDrawer({
    super.key,
    this.mode = ClienteFormMode.crear,
    this.initialCliente,
  });

  final ClienteFormMode mode;
  final ClienteModel? initialCliente;

  @override
  ConsumerState<ClienteFormDrawer> createState() => _ClienteFormDrawerState();
}

class _ClienteFormDrawerState extends ConsumerState<ClienteFormDrawer> {
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

  bool _isSaving = false;
  Map<String, String?> _errors = {};

  final _scrollController = ScrollController();
  final _representanteKey = GlobalKey();
  final _telefonoKey = GlobalKey();
  final _nitCiKey = GlobalKey();
  final _emailKey = GlobalKey();

  String? _flashingField;

  @override
  void initState() {
    super.initState();
    final c = widget.initialCliente;

    // 3. MAPEO DE DATOS REALES AL INICIAR
    _nitCiCtrl = TextEditingController(text: c?.ciCliente ?? '');
    _razonSocialCtrl = TextEditingController(text: c?.razonSocial ?? '');
    // Unimos nombre y apellido para el campo del representante
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
      errors['representante'] = 'El representante/nombre es requerido';
    }

    final telefono = _telefonoCtrl.text.trim();
    if (telefono.isEmpty) {
      errors['telefono'] = 'El teléfono es requerido';
    } else if (telefono.replaceAll(RegExp(r'\s+'), '').length < 8) {
      errors['telefono'] = 'El número parece ser muy corto';
    }

    final ci = _nitCiCtrl.text.trim();
    if (ci.isNotEmpty && !RegExp(r'^[0-9\-]+$').hasMatch(ci)) {
      errors['nitCi'] = 'El NIT/CI debe contener solo números o guiones';
    }

    final email = _emailCtrl.text.trim();
    if (email.isNotEmpty &&
        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+').hasMatch(email)) {
      errors['email'] = 'Email inválido';
    }

    setState(() => _errors = errors);
    // Si errors está vacío, significa que todo está bien y devuelve true.
    return errors.isEmpty;
  }

  // ───────────────────────────────────────── FORMATEO DE TELÉFONO ──
  String _formatearTelefono(String numero) {
    String tel = numero.trim();
    if (tel.isEmpty) return ''; // Se enviará vacío a la BD

    // Limpiamos espacios en blanco intermedios por si el usuario escribe "712 34 567"
    tel = tel.replaceAll(RegExp(r'\s+'), '');

    // Si ya tiene el formato correcto, lo dejamos
    if (tel.startsWith('+591')) return tel;

    // Si lo escribió como "59171234567" le agregamos el +
    if (tel.startsWith('591')) return '+$tel';

    // Si escribió solo el número "71234567", le agregamos todo
    return '+591 $tel';
  }

  // ───────────────────────────────────── GUARDADO REAL EN BD ──
  Future<void> _handleGuardar() async {
    // 1. SI LA VALIDACIÓN FALLA, SE DETIENE EL GUARDADO AQUÍ MISMO
    if (!_validar()) {
      _mostrarErroresSnackbar();
      _scrollToFirstError();
      return;
    }

    setState(() => _isSaving = true);

    // 2. SEPARAR NOMBRE Y APELLIDO
    final nombreParts = _representanteCtrl.text.trim().split(' ');
    final nombre = nombreParts.isNotEmpty ? nombreParts.first : '';
    final apellido = nombreParts.length > 1
        ? nombreParts.sublist(1).join(' ')
        : '';
    final isEmpresa = _tipoCliente == TipoCliente.empresa;

    // 3. LIMPIEZA DE DATOS (Evitar NULLs)
    // Si el usuario no escribió nada, enviamos '' (String vacío) o un valor por defecto.
    final ciLimpio = _nitCiCtrl.text.trim().isEmpty
        ? 'S/N'
        : _nitCiCtrl.text.trim();
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

    // 4. CONSTRUIR EL MODELO
    final clienteGuardar = ClienteModel(
      idCliente: widget.initialCliente?.idCliente,
      ciCliente: ciLimpio,
      nomCliente: nombre,
      apellidoCliente: apellido,
      razonSocial: isEmpresa ? razonLimpia : '', // Nunca enviará null
      email: emailLimpio,
      numTelefono: _formatearTelefono(
        _telefonoCtrl.text,
      ), // Formateado con +591
      numTelefono2: _formatearTelefono(
        _telefonoSecCtrl.text,
      ), // Formateado con +591
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
      Navigator.of(context).pop(); // Cierra el Drawer

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
                onSave: _handleGuardar,
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
        // 1. PANEL DE RESUMEN
        /*
        if (widget.mode == ClienteFormMode.editar &&
            widget.initialCliente != null) ...[
          ClienteSummaryPanel(cliente: widget.initialCliente!),
          const SizedBox(height: AppSpacing.xl),
        ],
        */

        // 2. IDENTIFICACIÓN (CON EL FIX DEL TIPO DE CLIENTE)
        _FlashWrap(
          isFlashing:
              _flashingField == 'nitCi' || _flashingField == 'representante',
          child: ClienteIdentificationCard(
            key: _representanteKey,
            nitCiController: _nitCiCtrl,
            razonSocialController: _razonSocialCtrl,
            representanteController: _representanteCtrl,
            tipoCliente: _tipoCliente,
            // 👇 SOLUCIÓN AL ERROR AQUÍ: Agregamos "as TipoCliente" 👇
            onTipoChanged: (v) => setState(() => _tipoCliente = v),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 3. CONTACTO
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
                    'Redirigiendo a WhatsApp para ${_telefonoCtrl.text}...',
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

        // 4. CRÉDITO
        ClienteCreditCard(
          permiteCredito: _permiteCredito,
          onPermiteCreditoChanged: (v) => setState(() => _permiteCredito = v),
          limiteController: _limiteCtrl,
          diasController: _diasCtrl,
          notasController: _notasCtrl,
        ),
        const SizedBox(height: AppSpacing.lg),

        // 5. PREFERENCIAS ADICIONALES (LIMPIO)
        ClientePreferencesCard(
          clientePrioritario: _clientePrioritario,
          onPrioritarioChanged: (v) => setState(() => _clientePrioritario = v),
          // Eliminamos facturación electrónica de aquí
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
