import 'package:flutter/material.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  // Iniciamos la opacidad en 0 (totalmente invisible)
  double _opacity = 0.0;

  @override
  void initState() {
    super.initState();
    // Un milisegundo después de pintar la pantalla negra, disparamos la animación
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _opacity = 1.0; // Cambiamos a 100% visible
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        // Aquí ocurre la magia del Fade In
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(milliseconds: 1500), // 1.5 segundos de duración
          curve: Curves.easeInOut,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logoAthlos.png',
                width: 180,
                fit: BoxFit.contain,
                // Si la imagen falla, mostramos un error en rojo en lugar de pantalla blanca
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.broken_image,
                  color: Colors.red,
                  size: 100,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                color: Color(0xFFFF0000),
              ),
            ],
          ),
        ),
      ),
    );
  }
}