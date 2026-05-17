import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Theme Mode Enum ──────────────────────────────────────────────────

class AppThemeMode {
  static const light = AppThemeMode._('light', 'Light', 'Clean and bright');
  static const dark = AppThemeMode._('dark', 'Dark', 'Easy on the eyes');
  static const synthwave =
      AppThemeMode._('synthwave', 'Synthwave \'84', '🎹 Neon grid');

  const AppThemeMode._(this.name, this.displayName, this.description);

  final String name;
  final String displayName;
  final String description;

  static const all = [light, dark, synthwave];

  static AppThemeMode? fromName(String n) =>
      all.where((m) => m.name == n).firstOrNull;
}

// ─── Synthwave '84 Palette ───────────────────────────────────────────

class SynthwaveColors {
  // Backgrounds
  static const bgPrimary = Color(0xFF0a0a1a);
  static const bgSecondary = Color(0xFF111133);
  static const bgSurface = Color(0xFF1a1a44);
  static const bgElevated = Color(0xFF222255);

  // Neon accents (from your Omarchy waybar.css)
  static const neonCoral = Color(0xFFFF9B71); // @rd1
  static const neonCyan = Color(0xFF00E5FF);
  static const neonMagenta = Color(0xFFFF007F);
  static const neonPurple = Color(0xFFB026FF);
  static const neonPink = Color(0xFFFF2D95);

  // Text
  static const textPrimary = Color(0xFFF0F0FF);
  static const textSecondary = Color(0xFFA0A0CC);
  static const textMuted = Color(0xFF6060AA);

  // Status
  static const xpGold = Color(0xFFFFD700);
  static const streakFlame = Color(0xFFFF5500);
  static const success = Color(0xFF00FF88);
  static const warning = Color(0xFFFF9B71);
  static const error = Color(0xFFFF007F);
}

// ─── Theme Definitions ──────────────────────────────────────────────

class AppThemes {
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF9B71),
          brightness: Brightness.light,
          primary: const Color(0xFFE8734A),
          secondary: const Color(0xFF4A6FA5),
          surface: Colors.white,
        ),
        textTheme: GoogleFonts.poppinsTextTheme(Typography.whiteMountainView),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: false,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF9B71),
          secondary: Color(0xFF00E5FF),
          surface: Color(0xFF1C1C2E),
          onSurface: Color(0xFFE0E0F0),
          tertiary: Color(0xFFFF007F),
        ),
        scaffoldBackgroundColor: const Color(0xFF0C0C18),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ).apply(
          bodyColor: const Color(0xFFE0E0F0),
          displayColor: const Color(0xFFFF9B71),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1C1C2E),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: Color(0xFF2A2A44),
              width: 1,
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF0C0C18),
        ),
      );

  static ThemeData get synthwaveTheme => ThemeData(
        useMaterial3: false,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: SynthwaveColors.neonCoral,
          secondary: SynthwaveColors.neonCyan,
          tertiary: SynthwaveColors.neonMagenta,
          surface: SynthwaveColors.bgSurface,
          onSurface: SynthwaveColors.textPrimary,
          background: SynthwaveColors.bgPrimary,
          error: SynthwaveColors.error,
        ),
        scaffoldBackgroundColor: SynthwaveColors.bgPrimary,
        textTheme: GoogleFonts.rajdhaniTextTheme(
          ThemeData.dark().textTheme,
        ).apply(
          bodyColor: SynthwaveColors.textPrimary,
          displayColor: SynthwaveColors.neonCoral,
        ),
        cardTheme: CardThemeData(
          color: SynthwaveColors.bgSurface,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(
              color: SynthwaveColors.neonCoral,
              width: 1.5,
            ),
          ),
          shadowColor: SynthwaveColors.neonCyan.withValues(alpha: 0.3),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          backgroundColor: SynthwaveColors.bgPrimary,
          foregroundColor: SynthwaveColors.neonCoral,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: SynthwaveColors.neonCoral,
            foregroundColor: SynthwaveColors.bgPrimary,
            elevation: 4,
            shadowColor: SynthwaveColors.neonCoral.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.rajdhani(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: SynthwaveColors.neonMagenta,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: CircleBorder(),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: SynthwaveColors.bgSecondary,
          selectedItemColor: SynthwaveColors.neonCoral,
          unselectedItemColor: SynthwaveColors.textMuted,
          type: BottomNavigationBarType.fixed,
        ),
        dividerTheme: const DividerThemeData(
          color: SynthwaveColors.bgElevated,
          thickness: 1,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: SynthwaveColors.bgSecondary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: SynthwaveColors.textMuted,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: SynthwaveColors.neonCyan,
              width: 2,
            ),
          ),
          hintStyle: GoogleFonts.rajdhani(
            color: SynthwaveColors.textMuted,
            fontSize: 14,
          ),
        ),
      );

  static ThemeData fromMode(AppThemeMode mode) {
    return switch (mode.name) {
      'dark' => darkTheme,
      'synthwave' => synthwaveTheme,
      _ => lightTheme,
    };
  }
}
