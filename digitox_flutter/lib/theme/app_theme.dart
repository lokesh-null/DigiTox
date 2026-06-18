import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colors
  static const Color bgPrimary = Color(0xFF0a0a0f);
  static const Color bgSecondary = Color(0xFF12121a);
  static const Color bgTertiary = Color(0xFF1a1a25);

  static const Color surface = Color(0x0AFFFFFF); // rgba(255, 255, 255, 0.04)
  static const Color surfaceHover = Color(0x12FFFFFF); // 0.07
  static const Color surfaceActive = Color(0x1AFFFFFF); // 0.1

  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryGlow = Color(0x4D6C5CE7); // 0.3
  static const Color primaryLight = Color(0xFFa29bfe);
  static const Color secondary = Color(0xFF00CEC9);
  static const Color secondaryGlow = Color(0x4D00CEC9);

  static const Color danger = Color(0xFFFF6B6B);
  static const Color success = Color(0xFF00B894);
  static const Color successGlow = Color(0x4D00B894); // 0.3
  static const Color warning = Color(0xFFFDCB6E);
  static const Color info = Color(0xFF74b9ff);

  static const Color textPrimary = Color(0xFFF0F0F5);
  static const Color textSecondary = Color(0x8CF0F0F5); // 0.55
  static const Color textTertiary = Color(0x4DF0F0F5); // 0.3

  static const Color border = Color(0x0FFFFFFF); // 0.06
  static const Color borderHover = Color(0x1EFFFFFF); // 0.12

  // Gradients
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFFa29bfe)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientSecondary = LinearGradient(
    colors: [Color(0xFF00CEC9), Color(0xFF55efc4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientDanger = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFee5a24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientMixed = LinearGradient(
    colors: [Color(0xFF6C5CE7), Color(0xFF00CEC9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient gradientWarm = LinearGradient(
    colors: [Color(0xFFfd79a8), Color(0xFFFDCB6E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Spacing (used for padding/margin constants)
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;
  static const double space2Xl = 48.0;

  // Radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgPrimary,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: bgSecondary,
        error: danger,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge: GoogleFonts.outfit(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
        displayMedium: GoogleFonts.outfit(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
        displaySmall: GoogleFonts.outfit(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: GoogleFonts.outfit(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: GoogleFonts.outfit(
          color: textPrimary,
          fontWeight: FontWeight.w700,
        ),
        headlineSmall: GoogleFonts.outfit(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.outfit(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(
          color: textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          color: textPrimary,
        ),
        bodySmall: GoogleFonts.inter(
          color: textSecondary,
        ),
      ),
      dividerColor: border,
    );
  }
}
