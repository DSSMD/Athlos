// lib/presentation/theme/app_colors.dart
// Este archivo define la paleta de colores de tu app, organizada por categorías para facilitar su uso y mantenimiento.
// Puedes ajustar los colores a tu marca y necesidades específicas. La idea es tener un sistema de colores consistente que puedas usar en toda la app.
// Para usar estos colores, simplemente importa este archivo y accede a los colores estáticos, por ejemplo: AppColors.primary500 para el rojo base de tu marca.
// Recuerda que puedes extender esta paleta con más colores o variantes según lo necesites, pero es importante mantener una estructura clara para facilitar su uso por todo el equipo de desarrollo.
// Si quieres, también puedes agregar funciones de utilidad para generar tonos dinámicos o para convertir colores a otros formatos, pero lo básico es tener esta paleta bien definida y documentada.


import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // === Colores de marca ===
  static const Color brandRed = Color(0xFFFF0000);
  static const Color brandBlack = Color(0xFF000000);
  static const Color brandWhite = Color(0xFFFFFFFF);

  // === Primary — rojo Athlos ===
  static const Color primary50 = Color(0xFFFFF1F1);
  static const Color primary100 = Color(0xFFFFD6D6);
  static const Color primary200 = Color(0xFFFF9999);
  static const Color primary400 = Color(0xFFFF4D4D);
  static const Color primary500 = Color(0xFFFF0000); // base
  static const Color primary600 = Color(0xFFCC0000);
  static const Color primary700 = Color(0xFF990000);
  static const Color primary900 = Color(0xFF660000);

  // === Neutral ===
  static const Color neutral50 = Color(0xFFFAFAFA);
  static const Color neutral100 = Color(0xFFF5F5F5);
  static const Color neutral200 = Color(0xFFE5E5E5);
  static const Color neutral400 = Color(0xFFA3A3A3);
  static const Color neutral500 = Color(0xFF737373);
  static const Color neutral600 = Color(0xFF525252);
  static const Color neutral800 = Color(0xFF262626);
  static const Color neutral950 = Color(0xFF0A0A0A);

  // === Semánticos ===
  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFEAB308);
  static const Color warningBg = Color(0xFFFEF9C3);
  static const Color error = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2563EB);
  static const Color infoBg = Color(0xFFDBEAFE);

  // === Backgrounds de la app ===
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFAFAFA);
  static const Color muted = Color(0xFFF5F5F5);
  static const Color sidebarDark = Color(0xFF0A0A0A);

  // === Aliases semánticos ===
  static const Color textPrimary = neutral950;
  static const Color textSecondary = neutral600;
  static const Color textMuted = neutral500;
  static const Color textDisabled = neutral400;
  static const Color border = neutral200;
  static const Color borderFocus = primary500;
  static const Color borderError = error;
}