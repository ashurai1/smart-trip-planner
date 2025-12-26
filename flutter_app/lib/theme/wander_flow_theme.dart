import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WanderFlowTheme {
  // --- COLORS ---
  static const Color primaryStart = Color(0xFFFF6A3D); // Sunset Orange
  static const Color primaryEnd = Color(0xFF5B2EFF); // Deep Purple
  static const Color secondaryStart = Color(0xFF1CB5E0); // Ocean Blue
  static const Color secondaryEnd = Color(0xFF0ED2F7); // Sky Teal
  
  static const Color backgroundLight = Color(0xFFF7F8FA);
  static const Color surfaceWhite = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A); // Deep Navy
  static const Color textSecondary = Color(0xFF64748B); // Muted Blue-Grey
  
  // --- GRADIENTS ---
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryStart, Color(0xFFFF3D77), primaryEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [secondaryStart, secondaryEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Colors.white, Color(0xFFF0F4F8)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // --- THEME DATA ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundLight,
      primaryColor: primaryStart,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: primaryStart,
        secondary: secondaryStart,
        background: backgroundLight,
        surface: surfaceWhite,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onBackground: textPrimary,
        onSurface: textPrimary,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
        displayMedium: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: textPrimary),
        titleLarge: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: GoogleFonts.inter(fontSize: 16, color: textPrimary),
        bodyMedium: GoogleFonts.inter(fontSize: 14, color: textSecondary),
        labelLarge: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
      ),

      // Icons
      iconTheme: const IconThemeData(color: textPrimary),
      
      // App Bar
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary),
        iconTheme: const IconThemeData(color: textPrimary),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryStart, width: 2),
        ),
        hintStyle: GoogleFonts.inter(color: Colors.grey[400]),
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }
}
