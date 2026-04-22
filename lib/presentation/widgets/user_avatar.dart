// lib/presentation/widgets/user_avatar.dart
// Widget para mostrar el avatar del usuario con sus iniciales y un indicador de presencia (en línea o fuera de línea)
// Este widget se utiliza en el menú de perfil del usuario autenticado para mostrar su información de manera visual y atractiva
// El diseño es moderno y minimalista, con un fondo de color generado a partir del nombre del usuario, texto blanco para las iniciales, y un indicador de presencia en la esquina inferior derecha del avatar
// IMPORTANTE: Este widget es independiente y se puede reutilizar en otras partes de la aplicación donde se requiera mostrar un avatar de usuario, como en listas de usuarios, comentarios, etc.

// NOTA: Para una implementación real, se podrían agregar más funcionalidades al avatar, como la posibilidad de cargar una imagen personalizada,
// mostrar un tooltip con el nombre completo al pasar el mouse, o agregar animaciones suaves al mostrar el indicador de presencia para mejorar la experiencia de usuario.

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.showPresence = false,
    this.isOnline = false,
  });

  final String name;
  final double size;
  final bool showPresence;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(name);
    final color = _colorForName(name);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: AppTypography.small.copyWith(
                color: AppColors.brandWhite,
                fontWeight: FontWeight.w600,
                fontSize: size * 0.35,
              ),
            ),
          ),
          if (showPresence)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.success : AppColors.neutral400,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.sidebarDark, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
  }

  Color _colorForName(String name) {
    // Usamos la paleta de tu app_colors.dart
    const palette = [
      AppColors.primary500, // Rojo Athlos
      AppColors.info, // Azul
      AppColors.success, // Verde
      AppColors.warning, // Amarillo
      AppColors.neutral600, // Gris oscuro
      AppColors.primary700, // Rojo oscuro
      AppColors.neutral800, // Casi negro
    ];
    final hash = name.codeUnits.fold<int>(0, (p, c) => p + c);
    return palette[hash % palette.length];
  }
}
