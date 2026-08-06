// Design-system spacing + corner-radius tokens, kept in their own file so
// `idp_colors.dart` can re-export the full token set without a circular
// import on `idp_theme.dart`.

class IDPSpacing {
  static const double unit = 8.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  static const double containerMargin = 20.0;
  static const double gutter = 16.0;
}

class IDPRadius {
  static const double sm = 8.0;
  static const double defaultRadius = 16.0; // 1rem
  static const double md = 24.0; // 1.5rem
  static const double lg = 32.0; // 2rem
  static const double xl = 48.0; // 3rem
  static const double pill = 9999.0;
  static const double full = 9999.0;
}
