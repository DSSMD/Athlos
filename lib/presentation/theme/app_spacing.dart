// lib/presentation/theme/app_spacing.dart
// Este archivo define las constantes de espaciado, bordes y sombras de tu app, organizadas por categorías para facilitar su uso y mantenimiento.
// Puedes ajustar estos valores a tu marca y necesidades específicas. La idea es tener un sistema de diseño consistente que puedas usar en toda la app.
// Para usar estos valores, simplemente importa este archivo y accede a las constantes estáticas, por ejemplo: AppSpacing.md para un espaciado medio de 12 píxeles.
// Recuerda que puedes extender esta escala con más valores según lo necesites, pero es importante mantener una estructura clara para facilitar su uso por todo el equipo de desarrollo.
// Si quieres, también puedes agregar funciones de utilidad para generar espaciados dinámicos o para calcular sombras más complejas, pero lo básico es tener esta escala bien definida y documentada.
// Además de los espaciados, también definimos aquí los radios de borde y las sombras para mantener todo lo relacionado con el diseño en un solo lugar.
// Este enfoque modular facilita la consistencia visual y la mantenibilidad de tu app a medida que crece y evoluciona.

import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  // Escala múltiplos de 4
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xl2 = 24;
  static const double xl3 = 32;
  static const double xl4 = 40;
  static const double xl5 = 48;
  static const double xl6 = 64;
}

class AppRadius {
  AppRadius._();

  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double full = 999; // pills / circular
}

class AppShadows {
  AppShadows._();

  // Elevación baja — cards, rows
  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0A000000), offset: Offset(0, 1), blurRadius: 2),
  ];

  // Elevación media — cards destacadas, dropdowns
  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x0F000000), offset: Offset(0, 2), blurRadius: 4),
    BoxShadow(color: Color(0x0A000000), offset: Offset(0, 1), blurRadius: 2),
  ];

  // Elevación alta — modales, diálogos
  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x14000000), offset: Offset(0, 10), blurRadius: 15),
    BoxShadow(color: Color(0x0A000000), offset: Offset(0, 4), blurRadius: 6),
  ];
}
