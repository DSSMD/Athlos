// lib/presentation/widgets/logout_confirmation_dialog.dart
// Widget para mostrar un diálogo de confirmación al cerrar sesión
// Este widget se utiliza en el UserProfileInfo para confirmar que el usuario realmente desea cerrar sesión
// El diálogo tiene un diseño moderno con un ícono de advertencia, un mensaje claro y botones para cancelar o confirmar la acción
// IMPORTANTE: Este widget es independiente y se puede reutilizar en otras partes de la aplicación donde se requiera una confirmación similar (por ejemplo, al eliminar una cuenta, al salir de una sección importante, etc.)
// NOTA: Para una implementación real, se podrían agregar animaciones al mostrar el diálogo, y se podrían personalizar los estilos de los botones para que se adapten al tema general de la aplicación.

import 'package:flutter/material.dart';

class LogoutConfirmationDialog extends StatelessWidget {
  const LogoutConfirmationDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.logout, color: Colors.red),
          SizedBox(width: 10),
          Text('¿Cerrar Sesión?'),
        ],
      ),
      // ... (Resto del contenido de tu diálogo)
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Cerrar Sesión'),
        ),
      ],
    );
  }
}
