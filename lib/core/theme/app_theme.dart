import 'package:flutter/material.dart';

class AppTheme {
  // Brand Accents
  static const Color brandCyan = Color(0xFF00E5FF);
  static const Color brandPurple = Color(0xFFA855F7);
  static const Color brandEmerald = Color(0xFF10B981);
  static const Color brandAmber = Color(0xFFF59E0B);
  static const Color brandCoral = Color(0xFFEF4444);

  // Dark Palette
  static const Color darkBg = Color(0xFF080B11);
  static const Color darkSurface = Color(0xFF0E131F);
  static const Color darkCard = Color(0xFF141A29);
  static const Color darkCardHover = Color(0xFF1B2337);
  static const Color darkBorder = Color(0x2600E5FF);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Light Palette
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardSubtle = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Dark Theme
  static ThemeData get darkTheme {
    final colorScheme = const ColorScheme.dark(
      primary: brandCyan,
      onPrimary: Color(0xFF001B24),
      primaryContainer: Color(0xFF004D59),
      onPrimaryContainer: Color(0xFFB8F5FF),
      secondary: brandPurple,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF4A1D75),
      onSecondaryContainer: Color(0xFFF3E8FF),
      surface: darkSurface,
      onSurface: darkTextPrimary,
      surfaceContainerHighest: darkCard,
      outline: darkBorder,
      outlineVariant: Color(0x1AFFFFFF),
      error: brandCoral,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: darkBg,
      fontFamily: 'Amiri', // bundled Arabic / multilingual fallback
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkTextPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: brandCyan),
      ),
      cardTheme: CardTheme(
        color: darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: brandCyan,
        unselectedItemColor: darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkCard,
        selectedColor: const Color(0x3300E5FF),
        labelStyle: const TextStyle(fontSize: 12, color: darkTextPrimary),
        secondaryLabelStyle: const TextStyle(fontSize: 12, color: brandCyan, fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: brandCyan, width: 1.5),
        ),
        hintStyle: const TextStyle(color: darkTextSecondary, fontSize: 14),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: darkBorder, width: 1),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkCard,
        contentTextStyle: const TextStyle(color: darkTextPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: brandCyan, width: 1),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0x1FFFFFFF),
        thickness: 1,
      ),
    );
  }

  // Light Theme
  static ThemeData get lightTheme {
    final colorScheme = const ColorScheme.light(
      primary: Color(0xFF0284C7),
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFE0F2FE),
      onPrimaryContainer: Color(0xFF0369A1),
      secondary: Color(0xFF7C3AED),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFEDE9FE),
      onSecondaryContainer: Color(0xFF5B21B6),
      surface: lightSurface,
      onSurface: lightTextPrimary,
      surfaceContainerHighest: lightCardSubtle,
      outline: lightBorder,
      outlineVariant: Color(0x1A000000),
      error: brandCoral,
      onError: Colors.white,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightBg,
      fontFamily: 'Amiri',
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: lightTextPrimary,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: Color(0xFF0284C7)),
      ),
      cardTheme: CardTheme(
        color: lightCard,
        elevation: 1,
        margin: EdgeInsets.zero,
        shadowColor: const Color(0x0F000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightSurface,
        selectedItemColor: Color(0xFF0284C7),
        unselectedItemColor: lightTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: lightCardSubtle,
        selectedColor: const Color(0x260284C7),
        labelStyle: const TextStyle(fontSize: 12, color: lightTextPrimary),
        secondaryLabelStyle: const TextStyle(fontSize: 12, color: Color(0xFF0284C7), fontWeight: FontWeight.bold),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF0284C7), width: 1.5),
        ),
        hintStyle: const TextStyle(color: lightTextSecondary, fontSize: 14),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: lightBorder, width: 1),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightTextPrimary,
        contentTextStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
      dividerTheme: const DividerThemeData(
        color: lightBorder,
        thickness: 1,
      ),
    );
  }
}
