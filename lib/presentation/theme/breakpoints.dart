import 'package:flutter/widgets.dart';

/// Breakpoints centralizados para responsive layout.
///
/// Usar context.isMobile / context.isDesktop / context.isWide
/// en lugar de LayoutBuilder local. Esto garantiza que todas las
/// páginas y el MainLayout cambien de layout en el mismo umbral,
/// evitando layouts mixtos (sidebar desktop + página mobile).
///
/// Breakpoint mobile = 1100px. Por debajo, la app fuerza layout
/// mobile (cards apiladas, bottom nav) para evitar tablas
/// desktop apretadas en pantallas chicas/medianas.
class AppBreakpoints {
  AppBreakpoints._();

  /// Bajo este ancho, layout mobile (bottom nav, cards apiladas).
  /// Sobre o igual a este, layout desktop (sidebar + tabla).
  static const double mobile = 1100;

  /// Sobre este ancho, layout wide (más aire, search más grande).
  static const double wide = 1300;
}

extension ResponsiveContext on BuildContext {
  /// True si la ventana mide < 1100px → renderizar layout mobile.
  bool get isMobile => MediaQuery.of(this).size.width < AppBreakpoints.mobile;

  /// True si la ventana mide >= 1100px → renderizar layout desktop.
  bool get isDesktop => MediaQuery.of(this).size.width >= AppBreakpoints.mobile;

  /// True si la ventana mide >= 1300px → desktop wide (más aire).
  bool get isWide => MediaQuery.of(this).size.width >= AppBreakpoints.wide;
}
