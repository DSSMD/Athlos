import 'package:flutter/material.dart';

class SingupPage extends StatefulWidget {
  const SingupPage({super.key});

  @override
  State<SingupPage> createState() => _SingupPageState();
}

class _SingupPageState extends State<SingupPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() {
    if (!_formKey.currentState!.validate()) return;
    
    // Simulación de carga (Solo Frontend)
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
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
              child: _buildRegisterForm(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botón de atrás
          Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05), // Fondo sutil
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded, // Icono moderno
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12), // Espacio antes del logo
          Center(
            child: Image.asset(
              'assets/images/logoAthlos.png',
              width: 140, // Ligeramente más pequeño para dar espacio a los campos
              height: 140,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF0000),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 28),

          // Título
          const Text(
            'Crear cuenta',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ingresa tus datos para registrarte en el sistema de gestión',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 32),

          // Campo Email
          _buildFieldLabel('Correo electrónico'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _emailController,
            hint: 'correo@athlos.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 18),

          // Campo Contraseña
          _buildFieldLabel('Contraseña'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _passwordController,
            hint: '••••••••',
            obscureText: _obscurePassword,
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
          const SizedBox(height: 18),

          // Campo Confirmar Contraseña
          _buildFieldLabel('Confirmar Contraseña'),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _confirmPasswordController,
            hint: '••••••••',
            obscureText: _obscureConfirmPassword,
            suffixIcon: GestureDetector(
              onTap: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(
                  _obscureConfirmPassword ? 'Mostrar' : 'Ocultar',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Botón Registrarse
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleRegister,
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
                      'Registrarse',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 24),
          
          // Separador visual
          Row(
            children: [
              Expanded(
                child: Divider(color: Colors.white.withValues(alpha: 0.1)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'O registrarse con',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ),
              Expanded(
                child: Divider(color: Colors.white.withValues(alpha: 0.1)),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Botón de Google
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () {}, // Acción vacía
              icon: Image.network(
                'https://img.icons8.com/color/48/000000/google-logo.png',
                width: 24,
                height: 24,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.g_mobiledata,
                    color: Colors.white,
                    size: 30,
                  );
                },
              ),
              label: const Text(
                'Google',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: const Color(0xFF1A1A1A),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Regresar al Login
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '¿Ya tienes una cuenta? ',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
              GestureDetector(
                onTap: () {
                  // Navegar de regreso al login
                  Navigator.pop(context);
                },
                child: const Text(
                  'Iniciar sesión',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFFFF4D4D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
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
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
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