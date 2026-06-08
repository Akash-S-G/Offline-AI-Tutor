import 'package:flutter/material.dart';
import 'idp_colors.dart';
import 'idp_typography.dart';

class IDPSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class IDPRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
}

class IDPTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: IDPColors.primary,
        primary: IDPColors.primary,
        secondary: IDPColors.secondary,
        surface: IDPColors.surface,
        error: IDPColors.error,
        background: IDPColors.background,
      ),
      scaffoldBackgroundColor: IDPColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: IDPColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: IDPColors.surface,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(IDPRadius.lg),
          side: const BorderSide(color: IDPColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: IDPColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: IDPSpacing.lg, vertical: IDPSpacing.md),
          minimumSize: const Size(64, 48), // Ensure accessibility minimum
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(IDPRadius.md)),
          textStyle: IDPTypography.button,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: IDPColors.primary,
          side: const BorderSide(color: IDPColors.border),
          padding: const EdgeInsets.symmetric(horizontal: IDPSpacing.lg, vertical: IDPSpacing.md),
          minimumSize: const Size(64, 48), // Ensure accessibility minimum
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(IDPRadius.md)),
          textStyle: IDPTypography.button,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: IDPColors.divider,
        thickness: 1,
        space: IDPSpacing.lg,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
}
