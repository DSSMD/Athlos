import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SplashScreenPage extends StatefulWidget {
  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  // Iniciamos la opacidad en 0 (totalmente invisible)
  double _opacity = 0.0;
  String _versionStr = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
    // Un milisegundo después de pintar la pantalla negra, disparamos la animación
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _opacity = 1.0; // Cambiamos a 100% visible
      });
    });
  }

  Future<void> _loadVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _versionStr = 'v${packageInfo.version}';
      });
    } catch (e) {
      // Ignorar error de carga si ocurre
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Center(
        // Aquí ocurre la magia del Fade In
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: const Duration(
            milliseconds: 1500,
          ), // 1.5 segundos de duración
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
              const CircularProgressIndicator(color: Color(0xFFFF0000)),
              if (_versionStr.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  _versionStr,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

