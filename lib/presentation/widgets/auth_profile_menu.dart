// lib/presentation/widgets/auth_profile_menu.dart
// Widget para mostrar el menú de perfil del usuario autenticado
// Este widget se utiliza en el MainLayout para mostrar el nombre del usuario, su rol, y un avatar con sus iniciales, además de permitir cerrar sesión al hacer clic en él
// El diseño es moderno y minimalista, con un fondo oscuro, texto blanco, y un avatar circular con un color de fondo rojo y las iniciales del usuario en blanco
// IMPORTANTE: Este widget es fundamental para la experiencia de usuario en Athlos Workspace, ya que permite al usuario ver su información básica de perfil y
// acceder a la funcionalidad de cerrar sesión de manera rápida y fácil.

// NOTA: Para una implementación real, se podrían agregar más funcionalidades al menú de perfil, como un enlace para editar el perfil, cambiar la contraseña,
// ver notificaciones, etc., y se podrían agregar animaciones suaves al mostrar el menú o al hacer clic en el avatar para mejorar la experiencia de usuario.   

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'logout_confirmation_dialog.dart';

class AuthProfileMenu extends ConsumerWidget {
  final bool isCollapsed;
  final bool showFullInfo;

  const AuthProfileMenu({
    super.key,
    this.isCollapsed = false,
    this.showFullInfo = true,
  });

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => const LogoutConfirmationDialog(),
    );

    if (confirm == true) {
      await ref.read(authServiceProvider).signOut();
    }
  }

  // Utilidad para extraer iniciales (Ej: "Rosa Rene" -> "RR")
  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].substring(0, parts[0].length > 1 ? 2 : 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos los datos reales del usuario
    final userProfileAsync = ref.watch(userProfileProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: InkWell(
        onTap: () => _handleLogout(context, ref),
        borderRadius: BorderRadius.circular(12),
        hoverColor: Colors.white10,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          // Usamos .when para manejar la carga de datos
          child: userProfileAsync.when(
            data: (profile) {

              final nombre = profile?['nombre'] ?? 'Usuario';
              final rolTexto = profile?['roles']?['nombre_rol'] ?? 'Sin Rol';              
              final iniciales = _getInitials(nombre);

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.red.shade700,
                    radius: 18,
                    child: Text(
                      iniciales,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (showFullInfo && !isCollapsed) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            nombre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            rolTexto, 
                            style: const TextStyle(color: Colors.white60, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_right, color: Colors.white24, size: 16),
                  ],
                ],
              );
            },
            // Estado de carga (mientras se trae el nombre de Supabase)
            loading: () => const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(backgroundColor: Colors.white24, radius: 18),
                SizedBox(width: 12),
                SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2))
              ],
            ),
            // Si ocurre un error al cargar
            error: (error, stack) => const Icon(Icons.error, color: Colors.red),
          ),
        ),
      ),
    );
  }
}