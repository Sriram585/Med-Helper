import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primary = Color(0xFF6366f1); // Indigo 500
  static const Color secondary = Color(0xFFA855F7); // Purple 500
  static const Color backgroundDark = Color(0xFF0f172a);
  static const Color backgroundLight = Color(0xFFf8fafc);
  static const Color textMain = Color(0xFF1E293B); // Slate 800
  static const Color textSecondary = Color(0xFF64748B); // Slate 500

  static const Color glassBg =
      Color(0xB3FFFFFF); // rgba(255, 255, 255, 0.7) -> 0.7 * 255 = 178 -> B2/B3
  static const Color glassBorder = Color(0x80FFFFFF); // 0.5

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: Colors.white,
        background: backgroundLight,
      ),
      textTheme: GoogleFonts.urbanistTextTheme(
        ThemeData.light().textTheme,
      ).apply(
        bodyColor: textMain,
        displayColor: textMain,
      ),
      useMaterial3: true,
      cardTheme: CardThemeData(
        color: glassBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: glassBorder, width: 1),
        ),
      ),
    );
  }

  // Exact CSS Gradient: linear-gradient(135deg, #fdfbfb 0%, #ebedee 100%)
  static const BoxDecoration backgroundDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFfdfbfb), Color(0xFFebedee)],
    ),
  );

  static BoxDecoration glassDecoration = BoxDecoration(
    color: glassBg,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: glassBorder),
    boxShadow: const [
      BoxShadow(
        color: Color(0x1A1F2687), // rgba(31, 38, 135, 0.1)
        blurRadius: 32,
        offset: Offset(0, 8),
      ),
    ],
  );
}
