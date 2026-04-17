// ============================================================================
// user_avatar.dart
// Ubicación sugerida: lib/presentation/widgets/user_avatar.dart
// Descripción: Avatar circular con iniciales. El color de fondo se asigna
// deterministamente a partir del nombre. Soporta indicador de presencia.
// ============================================================================

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
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
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
                  border: Border.all(color: AppColors.background, width: 2),
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
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Color _colorForName(String name) {
    const palette = [
      Color(0xFFFF0000), // rojo
      Color(0xFF2563EB), // azul
      Color(0xFF16A34A), // verde
      Color(0xFFEAB308), // amarillo
      Color(0xFF7C3AED), // violeta
      Color(0xFFDC2626), // rojo oscuro
      Color(0xFF0891B2), // cian
      Color(0xFFEA580C), // naranja
    ];
    final hash = name.codeUnits.fold<int>(0, (p, c) => p + c);
    return palette[hash % palette.length];
  }
}