import 'package:flutter/material.dart';
import 'idp_colors.dart';

class IDPTypography {
  static const String fontFamily = 'Inter';

  static const TextStyle displayLarge = TextStyle(fontSize: 57, fontWeight: FontWeight.w400, height: 1.12);
  static const TextStyle displayMedium = TextStyle(fontSize: 45, fontWeight: FontWeight.w400, height: 1.15);
  static const TextStyle displaySmall = TextStyle(fontSize: 36, fontWeight: FontWeight.w400, height: 1.22);
  
  static const TextStyle headlineLarge = TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.25);
  static const TextStyle headlineMedium = TextStyle(fontSize: 28, fontWeight: FontWeight.bold, height: 1.28);
  static const TextStyle headlineSmall = TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.33);

  static const TextStyle titleLarge = TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.27);
  static const TextStyle titleMedium = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4);
  static const TextStyle titleSmall = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5);

  static const TextStyle bodyLarge = TextStyle(fontSize: 16, fontWeight: FontWeight.normal, height: 1.5);
  static const TextStyle bodyMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.normal, height: 1.42);
  static const TextStyle bodySmall = TextStyle(fontSize: 12, fontWeight: FontWeight.normal, height: 1.5);

  static const TextStyle labelLarge = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, height: 1.42);
  static const TextStyle labelMedium = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.33);
  static const TextStyle labelSmall = TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.45);

  // Keep compatibility aliases
  static const TextStyle heading1 = displayLarge;
  static const TextStyle heading2 = headlineLarge;
  static const TextStyle heading3 = titleMedium;
  static const TextStyle subtitle = bodyLarge;
  static const TextStyle body = bodyMedium;
  static const TextStyle caption = labelMedium;
  static const TextStyle button = labelLarge;

  // Short HTML-style heading aliases (h1–h6) used by the math_studio screens.
  static const TextStyle h1 = displayLarge;
  static const TextStyle h2 = headlineLarge;
  static const TextStyle h3 = titleMedium;
  static const TextStyle h4 = titleSmall;
  static const TextStyle h5 = labelLarge;
  static const TextStyle h6 = labelMedium;

  // Stitch UI aliases
  static const TextStyle headlineLgMobile = headlineLarge;
  static const TextStyle titleMd = titleMedium;
  static const TextStyle labelMd = labelMedium;
  static const TextStyle bodyMd = bodyMedium;

  // Material 3 short-name aliases (Lg/Md/Sm) used across the UI migration.
  // Maps to the canonical M3 *Large / *Medium / *Small tokens above.
  static const TextStyle displayLg = displayLarge;
  static const TextStyle displayMd = displayMedium;
  static const TextStyle displaySm = displaySmall;
  static const TextStyle headlineLg = headlineLarge;
  static const TextStyle headlineMd = headlineMedium;
  static const TextStyle headlineSm = headlineSmall;
  static const TextStyle bodyLg = bodyLarge;
  static const TextStyle bodySm = bodySmall;
  static const TextStyle labelLg = labelLarge;
  static const TextStyle labelSm = labelSmall;

  // Optional explicit heading font family override (kept for backwards-compat
  // with screens that referenced it before the migration). Defaults to Inter.
  static const String headlineFontFamily = fontFamily;
}
