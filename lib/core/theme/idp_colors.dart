import 'package:flutter/material.dart';

class IDPColors {
  // Brand
  static const Color primary = Color(0xFF0B6E4F);
  static const Color primaryLight = Color(0xFFE6F5F0);
  static const Color primaryDark = Color(0xFF08523B);
  
  static const Color secondary = Color(0xFF3B82F6);
  static const Color secondaryLight = Color(0xFFEBF8FF);

  // Surface & Background
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // Text
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFF1F5F9);

  // Subject Specific Colors
  static Color getSubjectColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('math')) return const Color(0xFF6366F1);
    if (lower.contains('science')) return const Color(0xFF0D9488);
    if (lower.contains('english')) return const Color(0xFFD97706);
    if (lower.contains('kannada')) return const Color(0xFFDC2626);
    if (lower.contains('social')) return const Color(0xFF8B5CF6);
    return primary;
  }
}
