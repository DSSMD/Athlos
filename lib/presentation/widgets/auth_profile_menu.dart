// lib/presentation/widgets/auth_profile_menu.dart
// Widget para mostrar el menú de perfil del usuario autenticado, con su avatar, nombre, rol y la opción de cerrar sesión
// Este widget se utiliza en el MainLayout para mostrar la información del usuario en la barra lateral (en Desktop) o en el AppBar (en Mobile)
// El diseño es moderno y minimalista, con un avatar circular que muestra las iniciales del usuario, su nombre y rol en texto, y un ícono de flecha para indicar que es un menú desplegable (aunque en esta versión solo muestra la opción de cerrar sesión al hacer clic)
// IMPORTANTE: Este widget es independiente y se puede reutilizar en otras partes de la aplicación donde se requiera mostrar la información del usuario autenticado, como en un perfil de usuario o en una sección de configuración de cuenta.

// NOTA: Para una implementación real, se podrían agregar más opciones al menú desplegable, como la posibilidad de editar el perfil, cambiar la contraseña, ver la actividad reciente, etc., y se podrían agregar animaciones suaves al mostrar el menú para mejorar la experiencia de usuario. 

// lib/presentation/widgets/auth_profile_menu.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../theme/app_typography.dart';
import '../theme/app_colors.dart'; // Asegúrate de que este archivo exista
import 'user_avatar.dart'; // Importamos tu nuevo widget
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: InkWell(
        onTap: () => _handleLogout(context, ref),
        borderRadius: BorderRadius.circular(12),
        hoverColor: Colors.white10,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: userProfileAsync.when(
            data: (profile) {
              final nombre = profile?['nombre'] ?? 'Usuario';
              final rolTexto = profile?['roles']?['nombre_rol'] ?? 'Sin Rol';

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // USAMOS TU NUEVO WIDGET AQUÍ
                  UserAvatar(
                    name: nombre,
                    size: 36,
                    showPresence: true, // Ahora podemos mostrar si está online
                    isOnline: true,     // Aquí podrías conectar un provider de presencia
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
                            style: AppTypography.small.copyWith(
                              color: AppColors.brandWhite, // O el color que definas
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            rolTexto,
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_right, 
                        color: Colors.white24, size: 16),
                  ],
                ],
              );
            },
            loading: () => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar en estado de carga
                const UserAvatar(name: '?', size: 36),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 16, 
                    height: 16, 
                    child: CircularProgressIndicator(strokeWidth: 2)
                  ),
                ],
              ],
            ),
            error: (error, stack) => const Icon(Icons.error, color: Colors.red),
          ),
        ),
      ),
    );
  }
}