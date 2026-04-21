// ============================================================================
// app_colors.dart
// Ubicación sugerida: lib/presentation/theme/app_colors.dart
// Descripción: Tokens de color del Sistema de Diseño de Athlos.
// Centraliza brand, primary scale, neutrals, semánticos y backgrounds.
// ============================================================================

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