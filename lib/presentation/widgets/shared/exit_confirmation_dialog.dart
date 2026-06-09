import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ExitConfirmationDialog {
  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Obliga a tocar un botón
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0A0A0A), // Fondo oscuro Athlos
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: const BorderSide(color: Color(0xFF1A1A1A)),
          ),
          title: const Row(
            children: [
              Icon(Icons.exit_to_app, color: Colors.white70),
              SizedBox(width: 10),
              Text(
                '¿Salir de la aplicación?',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: const Text(
            'Estás a punto de cerrar el sistema. ¿Estás seguro?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF0000), // Rojo Athlos
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Salir'),
            ),
          ],
        );
      },
    );

    // Lógica de cierre total (Matar el proceso)
    if (result == true) {
      if (kIsWeb) {
        // En Web, los navegadores bloquean por seguridad cerrar pestañas mediante código.
        // Lo redirigimos a una pantalla en blanco o simulamos el cierre.
        SystemNavigator.pop(); 
      } else if (io.Platform.isAndroid || io.Platform.isIOS) {
        // Cierra la app en móvil de forma nativa (la saca de memoria)
        SystemNavigator.pop();
      } else {
        // Cierre agresivo para aplicaciones de Escritorio (Windows/Mac/Linux)
        io.exit(0);
      }
    }

    return result ?? false;
  }
}