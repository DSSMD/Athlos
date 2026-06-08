// lib/presentation/pages/auth/setup_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/usuario_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/usuario_provider.dart';

class SetupPage extends ConsumerStatefulWidget {
  const SetupPage({super.key});

  @override
  ConsumerState<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends ConsumerState<SetupPage> {
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  final _apellidoFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _telefonoFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _passwordConfirmFocusNode = FocusNode();

  bool _obscurePassword = true;
  bool _obscurePasswordConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    _apellidoFocusNode.dispose();
    _emailFocusNode.dispose();
    _telefonoFocusNode.dispose();
    _passwordFocusNode.dispose();
    _passwordConfirmFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final nombre = _nombreController.text.trim();
    final apellido = _apellidoController.text.trim();
    final email = _emailController.text.trim();
    final telefono = _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim();
    final password = _passwordController.text;

    try {
      // 1. Crear el usuario Administrador (invocando la Edge Function)
      final usuarioService = ref.read(usuarioServiceProvider);
      await usuarioService.crearUsuario(
        nombre: nombre,
        apellido: apellido,
        email: email,
        password: password,
        telefono: telefono,
        rol: UserRole.administrador,
        idArea: null,
        tarifaPagoBase: null,
      );

      // 2. Iniciar sesión automáticamente
      final authService = ref.read(authServiceProvider);
      await authService.signIn(
        email: email,
        password: password,
      );

      // 3. Invalidar providers para notificar a GoRouter y refrescar la UI
      ref.invalidate(needsAdminSetupProvider);
      ref.invalidate(userProfileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Sistema configurado con éxito! Bienvenido Administrador.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 1,
                ),
              ),
              child: _buildSetupForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSetupForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo e Identidad
          Center(
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0000),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Athlos Workspace',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Título de la sección
          const Text(
            'Configuración Inicial',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Se ha detectado el primer arranque del sistema. Registra la cuenta del administrador principal para continuar.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 24),

          // Campo Nombre
          _buildFieldLabel('Nombre *'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _nombreController,
            hint: 'Escribe tu nombre',
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _apellidoFocusNode.requestFocus(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El nombre es obligatorio';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Campo Apellido
          _buildFieldLabel('Apellido *'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _apellidoController,
            focusNode: _apellidoFocusNode,
            hint: 'Escribe tu apellido',
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _emailFocusNode.requestFocus(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El apellido es obligatorio';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Campo Email
          _buildFieldLabel('Correo electrónico *'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            hint: 'admin@athlos.com',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _telefonoFocusNode.requestFocus(),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'El correo electrónico es obligatorio';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                return 'Ingresa un correo electrónico válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Campo Teléfono
          _buildFieldLabel('Teléfono (Opcional)'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _telefonoController,
            focusNode: _telefonoFocusNode,
            hint: '+591 712 345 67',
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _passwordFocusNode.requestFocus(),
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                if (!RegExp(r'^\+?[0-9\s]+$').hasMatch(value.trim())) {
                  return 'Solo se permiten números y el signo +';
                }
                if (value.trim().length < 7) {
                  return 'El número es demasiado corto';
                }
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Campo Contraseña
          _buildFieldLabel('Contraseña de administrador *'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            hint: '••••••••',
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.next,
            onFieldSubmitted: (_) => _passwordConfirmFocusNode.requestFocus(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'La contraseña es obligatoria';
              }
              if (value.length < 8) {
                return 'La contraseña debe tener mínimo 8 caracteres';
              }
              return null;
            },
            suffixIcon: GestureDetector(
              onTap: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  _obscurePassword ? 'Mostrar' : 'Ocultar',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Campo Confirmar Contraseña
          _buildFieldLabel('Confirmar contraseña *'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _passwordConfirmController,
            focusNode: _passwordConfirmFocusNode,
            hint: '••••••••',
            obscureText: _obscurePasswordConfirm,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) {
              if (!_isLoading) _handleSetup();
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Confirma la contraseña';
              }
              if (value != _passwordController.text) {
                return 'Las contraseñas no coinciden';
              }
              return null;
            },
            suffixIcon: GestureDetector(
              onTap: () {
                setState(() {
                  _obscurePasswordConfirm = !_obscurePasswordConfirm;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  _obscurePasswordConfirm ? 'Mostrar' : 'Ocultar',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Mensaje de Error
          if (_errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF0000).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFF0000).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 16,
                    color: Color(0xFFFF4D4D),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFFF4D4D),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Botón Guardar / Configurar
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSetup,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0000),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFFF0000).withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Configurar Administrador',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Colors.white.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
    FocusNode? focusNode,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      validator: validator,
      style: const TextStyle(fontSize: 13, color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: Colors.white.withValues(alpha: 0.3),
        ),
        filled: true,
        fillColor: const Color(0xFF1A1A1A),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2A2A2A), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFF0000), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFF4D4D), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFFF4D4D), width: 1.5),
        ),
        errorStyle: const TextStyle(fontSize: 10, color: Color(0xFFFF4D4D)),
        suffixIcon: suffixIcon != null
            ? Align(
                widthFactor: 1.0,
                heightFactor: 1.0,
                alignment: Alignment.centerRight,
                child: suffixIcon,
              )
            : null,
      ),
    );
  }
}
