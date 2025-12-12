import 'package:flutter/material.dart';

/// Centralized theme configuration for easy modification
class AppTheme {
  // Primary Colors (Blue Theme)
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color primaryBlueDark = Color(0xFF1565C0);
  static const Color primaryBlueLighter = Color(0xFF42A5F5);

  // Secondary Colors (Green Theme for NDVI)
  static const Color primaryGreen = Color(0xFF2E8B57);
  static const Color primaryGreenDark = Color(0xFF1F5C3F);
  static const Color primaryGreenLight = Color(0xFF3DA566);

  // Dark Mode Colors
  static const Color darkBg = Color(0xFF1A1A1A);
  static const Color darkBgSecondary = Color(0xFF242424);
  static const Color darkBgTertiary = Color(0xFF2D2D2D);
  static const Color darkText = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFFF5252);
  static const Color info = Color(0xFF2196F3);

  /// Get dark theme configuration
  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: darkBg,
      appBarTheme: AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      colorScheme: const ColorScheme.dark(
        primary: primaryBlue,
        secondary: primaryBlueLighter,
        tertiary: primaryBlueDark,
        surface: darkBgSecondary,
        error: error,
        onSurface: darkText,
        onPrimary: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: darkBgSecondary,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkBgTertiary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        labelStyle: const TextStyle(color: darkTextSecondary),
        hintStyle: const TextStyle(color: darkTextSecondary),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: darkText,
          fontWeight: FontWeight.bold,
          fontSize: 32,
        ),
        displayMedium: TextStyle(
          color: darkText,
          fontWeight: FontWeight.bold,
          fontSize: 28,
        ),
        headlineSmall: TextStyle(
          color: darkText,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        titleLarge: TextStyle(
          color: darkText,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        bodyLarge: TextStyle(
          color: darkText,
          fontSize: 14,
        ),
        bodyMedium: TextStyle(
          color: darkTextSecondary,
          fontSize: 13,
        ),
        labelSmall: TextStyle(
          color: darkTextSecondary,
          fontSize: 12,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
        ),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: darkBgTertiary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade700),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade700),
          ),
        ),
      ),
    );
  }
}
