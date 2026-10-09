import 'package:flutter/material.dart';

/// Paleta pastel (laranja-pêssego, creme, menta, manteiga). Textos sobre
/// cores pastel usam os `on*` escuros para manter contraste >= 4.5:1.
abstract class AppColors {
  // Primary (pêssego)
  static const Color primary = Color(0xFFF6A97A);
  static const Color primaryVariant = Color(0xFFE98B5A);
  static const Color onPrimary = Color(0xFF4A2A18);

  // Secondary (menta)
  static const Color secondary = Color(0xFF9ED8C4);
  static const Color secondaryVariant = Color(0xFF6FBFA5);
  static const Color onSecondary = Color(0xFF1F3F35);

  // Background & Surface (creme)
  static const Color background = Color(0xFFFFF7F0);
  static const Color surface = Color(0xFFFFFCF8);
  static const Color onBackground = Color(0xFF3B2F2A);
  static const Color onSurface = Color(0xFF3B2F2A);

  // Dark
  static const Color backgroundDark = Color(0xFF1F1815);
  static const Color surfaceDark = Color(0xFF2A211D);
  static const Color onSurfaceDark = Color(0xFFF5E9E0);

  // Error
  static const Color error = Color(0xFFD95D54);
  static const Color onError = Color(0xFFFFFFFF);

  // Gamificação (streak, XP, progresso)
  static const Color streak = Color(0xFFFFB27A);
  static const Color streakDark = Color(0xFFF08A4B);
  static const Color xp = Color(0xFFFFD88A);
  static const Color xpDark = Color(0xFFF2B84B);
  static const Color success = Color(0xFF86CFA3);
  static const Color successDark = Color(0xFF3F9A68);

  // Acentos pastel (tópicos, trilha)
  static const Color sky = Color(0xFFA8D0F0);
  static const Color lilac = Color(0xFFCDB8F0);
  static const Color rose = Color(0xFFF2B5C4);

  // Neutral (tons quentes)
  static const Color grey100 = Color(0xFFF7F1EC);
  static const Color grey200 = Color(0xFFEFE6DF);
  static const Color grey300 = Color(0xFFE3D8CF);
  static const Color grey400 = Color(0xFFC9BBB0);
  static const Color grey500 = Color(0xFFA89A90);
  static const Color grey600 = Color(0xFF857870);
  static const Color grey700 = Color(0xFF675C55);
  static const Color grey800 = Color(0xFF4A413C);
  static const Color grey900 = Color(0xFF2E2723);
}
