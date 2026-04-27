// lib/presentation/theme/app_typography.dart
// Este archivo define la tipografía de tu app, organizada por estilos para facilitar su uso y mantenimiento.
// Puedes ajustar los estilos a tu marca y necesidades específicas. La idea es tener un sistema de tipografía consistente que puedas usar en toda la app.
// Para usar estos estilos, simplemente importa este archivo y accede a los estilos estáticos, por ejemplo: AppTypography.h1 para un título grande.
// Recuerda que puedes extender esta tipografía con más estilos según lo necesites, pero es importante mantener una estructura clara para facilitar su uso por todo el equipo de desarrollo.
// Si quieres, también puedes agregar funciones de utilidad para generar estilos dinámicos o para calcular tamaños de fuente más complejos, pero lo básico es tener esta tipografía bien definida y documentada.

import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Montserrat';

  // H1 — 32px / 500
  static const TextStyle h1 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w500,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  // H2 — 24px / 500
  static const TextStyle h2 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: AppColors.textPrimary,
  );

  // H3 — 20px / 500
  static const TextStyle h3 = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w500,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  // Body — 16px / 400
  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  // Small — 14px / 400
  static const TextStyle small = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.textSecondary,
  );

  // Caption — 12px / 400
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textMuted,
  );

  static TextStyle? get label => null;

  static TextStyle? get smallBold => null;
}
