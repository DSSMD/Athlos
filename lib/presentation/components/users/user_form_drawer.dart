// ============================================================================
// user_form_drawer.dart
// Ubicación sugerida: lib/presentation/components/user_form_drawer.dart
// Descripción: Formulario de crear/editar usuario.
// ============================================================================

// lib/presentation/components/user_form_drawer.dart

import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

import '../../widgets/users/custom_text_field.dart';
//import '../../widgets/users/role_badge.dart';
import '../../widgets/users/role_dropdown.dart';
//import '../../widgets/users/status_badge.dart';
import '../../widgets/users/loading_spinner.dart';

// 1. IMPORTAMOS EL MODELO REAL Y ELIMINAMOS EL MOCK
import '../../../domain/models/usuario_model.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/usuario_provider.dart';

/// API pública — llamar con `showUserFormDrawer(context, initialUser: ...)`.
Future<void> showUserFormDrawer(
  BuildContext context, {
  UsuarioModel? initialUser,
}) {
  final isMobile = MediaQuery.of(context).size.width < 900;

  if (isMobile) {
    // Mobile: pantalla completa que sube desde abajo
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, _, _) => UserFormDrawer(initialUser: initialUser),
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
      child: UserFormDrawer(initialUser: initialUser),
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

class UserFormDrawer extends ConsumerStatefulWidget {
  const UserFormDrawer({super.key, this.initialUser});
  final UsuarioModel? initialUser;

  @override
  ConsumerState<UserFormDrawer> createState() => _UserFormDrawerState();
}

// ══════════════════════════════════════════════════════════════════════════════
// ESTADO DEL FORMULARIO
// ══════════════════════════════════════════════════════════════════════════════

class _UserFormDrawerState extends ConsumerState<UserFormDrawer> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _apellidoCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _telefonoCtrl;
  late final TextEditingController _passCtrl;
  late final TextEditingController _passConfirmCtrl;

  UserRole? _rol;
  bool _activo = true;
  bool _showPassword = false;
  bool _showPasswordConfirm = false;

  // Permisos seleccionados.
  final Set<String> _permisos = {};
  final _formKey = GlobalKey<FormState>();

  final _tarifaController = TextEditingController();
  int? _selectedAreaId;

  // TODO: agregar permisos posteriormente
  static const _allPermisos = [
    'Usuarios',
    'Inventario',
    'Ventas',
    'Producción',
    'Reportes',
    'Caja',
    'Clientes',
    'Consulta',
    'Dashboard',
  ];

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final u = widget.initialUser;

    String nombre = '';
    String apellido = '';

    if (u != null) {
      final parts = u.name.split(' ');
      nombre = parts.isNotEmpty ? parts.first : '';
      apellido = parts.length > 1 ? parts.sublist(1).join(' ') : '';

      // 💡 CORRECCIÓN: Usamos la nueva extensión de UserRole
      _permisos.addAll(u.role.defaultPermissions);

      if (u.isTrabajador) {
        _selectedAreaId = u.idArea?.toInt();

        _tarifaController.text = u.tarifaPagoBase?.toStringAsFixed(2) ?? '0.00';
      }
    }

    _nombreCtrl = TextEditingController(text: nombre);
    _apellidoCtrl = TextEditingController(text: apellido);
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _telefonoCtrl = TextEditingController(text: u?.phone ?? '');
    _passCtrl = TextEditingController();
    _passConfirmCtrl = TextEditingController();

    _rol = u?.role;
    _activo = u?.status != UserStatus.inactivo;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _apellidoCtrl.dispose();
    _emailCtrl.dispose();
    _telefonoCtrl.dispose();
    _passCtrl.dispose();
    _passConfirmCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // MÉTODOS DE GUARDADO Y LÓGICA
  // ══════════════════════════════════════════════════════════════════════════════
  Future<void> _handleSave() async {
    // 1. Validar que los campos de texto cumplan las reglas
    if (!_formKey.currentState!.validate()) return;

    // 2. Validar que se haya elegido un Rol
    if (_rol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un rol')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final notifier = ref.read(usuariosProvider.notifier);

      final bool requiresLabourData =
          (_rol == UserRole.produccion || _rol == UserRole.cajas);

      final int? finalAreaId = requiresLabourData ? _selectedAreaId : null;
      final double? finalTarifa = requiresLabourData
          ? double.tryParse(_tarifaController.text)
          : null;

      if (_isEditing) {
        // ACTUALIZAR
        await notifier.actualizarUsuario(
          widget.initialUser!.id,
          nombre: _nombreCtrl.text.trim(),
          apellido: _apellidoCtrl.text.trim(),
          telefono: _telefonoCtrl.text.trim().isEmpty
              ? null
              : _telefonoCtrl.text.trim(),
          rol: _rol!,
          activo: _activo,
          idArea: finalAreaId,
          tarifaPagoBase: finalTarifa,
          // TODO (Permisos): Enviar la lista de permisos seleccionados: permisos: _permisos.toList(),
        );
      } else {
        // CREAR
        await notifier.crearUsuario(
          nombre: _nombreCtrl.text.trim(),
          apellido: _apellidoCtrl.text.trim(),
          telefono: _telefonoCtrl.text.trim().isEmpty
              ? null
              : _telefonoCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text,
          rol: _rol!,
          idArea: finalAreaId,
          tarifaPagoBase: finalTarifa,
        );
      }

      // Si todo salió bien:
      if (mounted) {
        Navigator.pop(context); // Cerramos el drawer
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing ? 'Usuario actualizado' : 'Usuario creado con éxito',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 1. Mensaje por defecto por si falla otra cosa
      String mensajeError =
          'Ocurrió un error inesperado al guardar el usuario.';

      // 2. Interceptamos el error exacto de Supabase
      if (e.toString().contains('already been registered')) {
        mensajeError =
            'Este correo electrónico ya pertenece a una cuenta registrada.';
      } else {
        // Mantenemos el error original para otros casos
        mensajeError = e.toString().replaceAll('Exception: ', '');
      }

      // 3. Mostramos la notificación flotante con el estilo Athlos
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    mensajeError,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            margin: const EdgeInsets.all(AppSpacing.lg),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // TODO: Agregar lógica para actualizar permisos dinámicamente si el rol cambia (opcional pero mejora UX)
  void _onRoleChanged(UserRole? newRole) {
    if (newRole == null) return;

    setState(() {
      _rol = newRole;
      _permisos.clear();
      // 💡 Directo, elegante y centralizado
      _permisos.addAll(newRole.defaultPermissions);
    });
  }

  bool get _isEditing => widget.initialUser != null;

  // ══════════════════════════════════════════════════════════════════════════════
  // BUILD PRINCIPAL
  // ══════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;
    final width = isMobile ? double.infinity : 460.0;

    return Material(
      color: AppColors.background,
      child: SizedBox(
        width: width,
        height: double.infinity,
        child: Column(
          children: [
            _Header(
              isEditing: _isEditing,
              onClose: () => Navigator.pop(context),
            ),
            Expanded(child: _buildForm()),
            _Footer(
              onCancel: () => Navigator.pop(context),
              onSave: _handleSave,
              isEditing: _isEditing,
              isSaving: _isSaving,
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // FORMULARIO PRINCIPAL
  // ══════════════════════════════════════════════════════════════════════════════

  Widget _buildForm() {
    return Form(
      key: _formKey, // 💡 Necesaria para activar los validators
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- SECCIÓN: DATOS PERSONALES ---
            _Section(
              title: 'Datos personales',
              child: Column(
                children: [
                  CustomTextField(
                    label: 'Nombre',
                    isRequired: true,
                    controller: _nombreCtrl,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'El nombre es obligatorio'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CustomTextField(
                    label: 'Apellido',
                    isRequired: true,
                    controller: _apellidoCtrl,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'El apellido es obligatorio'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CustomTextField(
                    label: 'Email',
                    hint: 'correo@athlos.com',
                    isRequired: true,
                    controller: _emailCtrl,
                    enabled:
                        !_isEditing, // 💡 Opcional: Bloquear email en edición
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'El email es obligatorio';
                      }
                      // 💡 MEJORA: Validación robusta con RegEx para correos
                      final emailRegEx = RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                      );
                      if (!emailRegEx.hasMatch(v.trim())) {
                        return 'Ingresa un email válido (ej: nombre@dominio.com)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CustomTextField(
                    label: 'Teléfono',
                    hint: '+591 712 345 67',
                    isOptional: true,
                    controller: _telefonoCtrl,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      // 💡 MEJORA: Si escriben algo, validamos que sean números o el signo '+'
                      if (v != null && v.trim().isNotEmpty) {
                        final phoneRegEx = RegExp(r'^\+?[0-9\s]+$');
                        if (!phoneRegEx.hasMatch(v)) {
                          return 'Solo se permiten números y el signo +';
                        }
                        if (v.length < 7) {
                          return 'El número es muy corto';
                        }
                      }
                      return null; // Como es opcional, si está vacío está bien
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // --- SECCIÓN: ACCESO AL SISTEMA ---
            _Section(
              title: 'Acceso al sistema',
              child: Column(
                children: [
                  RoleDropdown(value: _rol, onChanged: _onRoleChanged),

                  // 💡 SOLO MOSTRAR CONTRASEÑA SI ES USUARIO NUEVO
                  if (!_isEditing) ...[
                    const SizedBox(height: AppSpacing.lg),
                    CustomTextField(
                      label: 'Contraseña',
                      isRequired: true,
                      controller: _passCtrl,
                      obscureText: !_showPassword,
                      suffix: _buildShowPasswordButton(
                        visible: _showPassword,
                        onToggle: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                      validator: (v) {
                        if (v == null || v.length < 8) {
                          return 'Mínimo 8 caracteres';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    CustomTextField(
                      label: 'Confirmar contraseña',
                      isRequired: true,
                      controller: _passConfirmCtrl,
                      obscureText: !_showPasswordConfirm,
                      suffix: _buildShowPasswordButton(
                        visible: _showPasswordConfirm,
                        onToggle: () => setState(
                          () => _showPasswordConfirm = !_showPasswordConfirm,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Debes confirmar la contraseña';
                        }
                        if (v != _passCtrl.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ════════════════════════════════════════════════════════════════
            // NUEVO: SECCIÓN DINÁMICA DE RECURSOS HUMANOS
            // Solo aparece si el rol seleccionado es Producción o Cajas
            // ════════════════════════════════════════════════════════════════
            if (_rol == UserRole.produccion || _rol == UserRole.cajas) ...[
              _Section(
                title: 'Datos Laborales',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Área asignada',
                      style: AppTypography.small.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    ref
                        .watch(areasProvider)
                        .when(
                          loading: () => const SizedBox(
                            height: 50,
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          error: (err, stack) => Text(
                            'Error al cargar áreas',
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                          data: (areas) {
                            // 1. FILTRADO: Filtramos la lista según el rol seleccionado
                            final areasFiltradas = areas.where((area) {
                              if (_rol == UserRole.produccion) {
                                // IDs 1, 2, 3 son de Producción
                                return area['id_area'] == 1 ||
                                    area['id_area'] == 2 ||
                                    area['id_area'] == 3;
                              } else if (_rol == UserRole.cajas) {
                                // ID 4 es de Ventas/Cajas
                                return area['id_area'] == 4;
                              }
                              return false;
                            }).toList();

                            // 2. RECUPERACIÓN SEGURA: Verificamos si el ID
                            // existe dentro de la lista YA FILTRADA
                            final bool areaExists = areasFiltradas.any(
                              (a) => a['id_area'] == _selectedAreaId,
                            );

                            final int? safeAreaId = areaExists
                                ? _selectedAreaId
                                : null;

                            return DropdownButtonFormField<int>(
                              initialValue:
                                  safeAreaId, // <-- Usamos la variable segura
                              decoration: InputDecoration(
                                hintText: 'Seleccione un área',
                                filled: true,
                                fillColor: AppColors.neutral100,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.md,
                                  ),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              // 3. RENDERIZADO: Pintamos solo las áreas filtradas
                              items: areasFiltradas.map((area) {
                                return DropdownMenuItem<int>(
                                  value: area['id_area'] as int,
                                  child: Text(area['nombre_area'] as String),
                                );
                              }).toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedAreaId = val),
                              validator: (val) {
                                if (val == null) {
                                  return 'Por favor seleccione un área';
                                }
                                return null;
                              },
                            );
                          },
                        ),
                    const SizedBox(height: AppSpacing.lg),

                    Text(
                      'Tarifa de pago base (Bs.)',
                      style: AppTypography.small.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    CustomTextField(
                      controller: _tarifaController,
                      hint: '0.00',
                      // Ocultamos la label original de tu CustomTextField para usar el Text de arriba
                      label: '',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Ingrese la tarifa base';
                        }

                        if (val.contains(',')) {
                          return 'Use punto (.) para decimales, no coma';
                        }
                        final numero = double.tryParse(val.trim());
                        if (numero == null) {
                          return 'Ingrese un número válido';
                        }
                        if (numero < 0) {
                          return 'La tarifa no puede ser negativa';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            // ════════════════════════════════════════════════════════════════
            // --- SECCIÓN: PERMISOS (ESTÉTICO EN ESTE SPRINT) ---
            _Section(
              title: 'Permisos',
              subtitle: _rol == UserRole.invitado
                  ? 'Los invitados solo tienen permisos de consulta (no editables).'
                  : 'Se sugieren según el rol, pero podés editarlos manualmente.',
              child: Column(
                children: _allPermisos.map((p) {
                  final checked = _permisos.contains(p);
                  // Verificamos si el rol actual es invitado
                  final isInvitado = _rol == UserRole.invitado;

                  return _PermissionCheckRow(
                    label: p,
                    checked: checked,
                    onChanged: isInvitado
                        ? null
                        : (v) {
                            setState(() {
                              if (v == true) {
                                _permisos.add(p);
                              } else {
                                _permisos.remove(p);
                              }
                            });
                          },
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // --- SECCIÓN: ESTADO ---
            _Section(
              title: 'Estado',
              child: _SwitchRow(
                title: 'Usuario activo',
                subtitle: 'Los usuarios inactivos no pueden iniciar sesión.',
                value: _activo,
                onChanged: (v) => setState(() => _activo = v),
              ),
            ),

            const SizedBox(height: AppSpacing.xl2),
          ],
        ),
      ),
    );
  }

  Widget _buildShowPasswordButton({
    required bool visible,
    required VoidCallback onToggle,
  }) {
    return TextButton(
      onPressed: onToggle,
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        foregroundColor: AppColors.textSecondary,
      ),
      child: Text(
        visible ? 'Ocultar' : 'Mostrar',
        style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
} // <-- AQUÍ CIERRA LA CLASE DEL ESTADO

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
              style: FilledButton.styleFrom(
                foregroundColor: AppColors.primary500,
              ),
              onPressed: isSaving ? null : onCancel,
              child: const Text('Cancelar'),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: Colors.white
              ),
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

// ══════════════════════════════════════════════════════════════════════════════
// SECTION — card con título + contenido
// ══════════════════════════════════════════════════════════════════════════════

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.subtitle});
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: AppTypography.caption),
          ],
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// PERMISSION CHECK ROW
// ══════════════════════════════════════════════════════════════════════════════

class _PermissionCheckRow extends StatelessWidget {
  const _PermissionCheckRow({
    required this.label,
    required this.checked,
    this.onChanged,
  });
  final String label;
  final bool checked;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    // 💡 Detectamos si está bloqueado (cuando onChanged es null)
    final isDisabled = onChanged == null;

    return InkWell(
      // 💡 CORRECCIÓN: Si está bloqueado, pasamos null al onTap.
      // Esto apaga el efecto de onda y hace que no sea clickeable.
      onTap: isDisabled ? null : () => onChanged!(!checked),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: checked,
                onChanged:
                    onChanged, // El Checkbox ya maneja el null automáticamente
                activeColor: AppColors.primary500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // 💡 MEJORA UX: El texto se pone gris si está bloqueado
            Text(
              label,
              style: AppTypography.small.copyWith(
                color: isDisabled ? AppColors.textMuted : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// ══════════════════════════════════════════════════════════════════════════════
// SWITCH ROW
// ══════════════════════════════════════════════════════════════════════════════

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppTypography.small.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTypography.caption),
            ],
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}
