import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Sunset Palette
  static const Color primaryColor = Color(0xFFFF5F6D); // Sunset Orange
  static const Color secondaryColor = Color(0xFF6A82FB); // Sky Blue/Indigo
  static const Color accentColor = Color(0xFFFFC371); // Golden Sun
  static const Color backgroundColor = Color(0xFFF9FAFB); // Clean Off-White
  static const Color surfaceColor = Colors.white;
  static const Color textMain = Color(0xFF102A43);
  static const Color textSub = Color(0xFF627D98);

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: backgroundColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: surfaceColor,
      background: backgroundColor,
      error: Color(0xFFE53E3E),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
    ),
    
    // Typography
    textTheme: TextTheme(
      displayLarge: GoogleFonts.poppins(color: textMain, fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.poppins(color: textMain, fontWeight: FontWeight.bold),
      headlineMedium: GoogleFonts.poppins(color: textMain, fontWeight: FontWeight.bold),
      headlineSmall: GoogleFonts.poppins(color: textMain, fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.inter(color: textMain, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.inter(color: textMain),
      bodyMedium: GoogleFonts.inter(color: textSub),
    ),

    // Card Theme (Glassmorphism base)
    // cardTheme: const CardTheme(
    //   color: surfaceColor,
    //   elevation: 0,
    //   margin: EdgeInsets.symmetric(vertical: 8),
    // ),

    // Input Decoration
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(color: textSub),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: primaryColor.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
      ),
    ),

    // Page Transitions
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
      },
    ),
  );
}
